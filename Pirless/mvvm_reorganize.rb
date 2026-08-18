#!/usr/bin/env ruby
# frozen_string_literal: true
# encoding: utf-8

# =============================================================================
#  mvvm_reorganize.rb  —  Pirless Xcode MVVM Project Organizer
# =============================================================================
#
#  WHAT IT DOES
#  ─────────────
#  Phase 0  Pre-flight  : validates paths, detects project type, backs up
#                         .xcodeproj before touching anything.
#
#  Phase 1  Scaffold    : creates the canonical MVVM directory tree.
#
#  Phase 2  Source Move : moves Swift files from the Feature-based layout into
#                         Models/, Views/{Details,Map,Shared}/, ViewModels/,
#                         Services/. Files already in the right bucket are
#                         skipped.
#
#  Phase 3  Resources   : moves Assets.xcassets (and any other resource files)
#                         into a Resources/ sub-folder inside the source root.
#
#  Phase 4  .xcodeproj  : two distinct paths —
#
#    ① PBXFileSystemSynchronizedRootGroup (Xcode 16+)
#      The project already uses Xcode's FS-sync groups. Every file move made
#      in Phases 1-3 is automatically reflected in Xcode the next time the
#      project is opened. No xcodeproj gem is needed; this phase just
#      validates the anchor path and prints the new tree.
#
#    ② Traditional PBXGroup projects
#      Uses the 'xcodeproj' gem to: remove stale/dangling red references,
#      rebuild all group hierarchies to match the new MVVM layout, add a
#      blue Folder Reference for Resources/, and re-save the project file.
#
#  USAGE
#  ─────
#    # 1. Install the gem (only needed for traditional, non-FS-synced projects)
#    gem install xcodeproj
#
#    # 2. Run from the directory that contains Pirless.xcodeproj
#    cd /path/to/PM25_Prediction/Pirless
#    ruby mvvm_reorganize.rb             # live run
#    ruby mvvm_reorganize.rb --dry-run   # preview only — zero disk changes
#
#  SAFETY
#  ──────
#  • A timestamped backup of .xcodeproj is created before any changes.
#  • --dry-run shows every action without executing it.
#  • The script is idempotent: running it a second time is a no-op.
# =============================================================================

require 'fileutils'
require 'pathname'
require 'time'

# ─────────────────────────────────────────────────────────────────────────────
#  Terminal output helpers
# ─────────────────────────────────────────────────────────────────────────────

module Log
  R = "\e[0m"
  def self.header(m) = puts("\n\e[1;34m▶  #{m}#{R}")
  def self.ok(m)     = puts("\e[32m   ✓  #{m}#{R}")
  def self.warn(m)   = puts("\e[33m   ⚠  #{m}#{R}")
  def self.error(m)  = puts("\e[31m   ✗  #{m}#{R}")
  def self.info(m)   = puts("       #{m}")
  def self.dry(m)    = puts("\e[33m   ~  [DRY-RUN] #{m}#{R}")
  def self.tree(m)   = puts("\e[36m       #{m}#{R}")
end

# ─────────────────────────────────────────────────────────────────────────────
#  Configuration — edit these constants to adapt to another project
# ─────────────────────────────────────────────────────────────────────────────

DRY_RUN      = ARGV.include?('--dry-run')
PROJECT_ROOT = Pathname.new(Dir.pwd)
XCODEPROJ    = PROJECT_ROOT.glob('*.xcodeproj').first

# Derived paths (resolved after XCODEPROJ is confirmed in preflight)
PBXPROJ_PATH  = XCODEPROJ ? (XCODEPROJ / 'project.pbxproj') : nil

# The folder that the Xcode target's source root points at.
# For this project it is Pirless/Pirless/ relative to the repo root.
SOURCE_ROOT  = PROJECT_ROOT / 'Pirless'

# ── MVVM top-level buckets ────────────────────────────────────────────────────
MVVM_DIRS = %w[Models Views ViewModels Services].freeze

# ── Feature-folder → MVVM-Views mapping ──────────────────────────────────────
#    Key   = path relative to SOURCE_ROOT that exists TODAY
#    Value = destination path relative to SOURCE_ROOT
FEATURE_MAP = {
  'Features/Details' => 'Views/Details',
  'Features/Map'     => 'Views/Map',
  'Features/Shared'  => 'Views/Shared',
}.freeze

# ── Files anchored at the SOURCE_ROOT level (never reclassified) ──────────────
ROOT_ANCHORED = %w[PirlessApp.swift ContentView.swift].freeze

# ── Extensions that classify a file/directory as a resource ──────────────────
RESOURCE_EXTENSIONS = %w[
  .xcassets .json .strings .stringsdict .plist
  .mp3 .wav .aac .m4a .mp4 .mov
  .html .css .js .geojson
].freeze

# ── MVVM classification rules (first match wins) ─────────────────────────────
#    Each rule has a :bucket and either a :name (regex on filename-without-ext)
#    or a :body (regex on file content).
CLASSIFICATION_RULES = [
  # ViewModels — must come before Views to intercept "SomethingViewModel"
  { bucket: 'ViewModels', name: /ViewModel/i },
  { bucket: 'ViewModels', body: /\bObservableObject\b|@Published\b|\bclass\s+\w+ViewModel\b/ },

  # Models — data structs / Codable types that are not views
  { bucket: 'Models', name: /(?<![Vv]iew)Model(?![Vv]iew)/i },
  { bucket: 'Models', body: /\bstruct\s+\w+[^{]*\bIdentifiable\b|\bCodable\b|\bDecodable\b/ },

  # Services / infrastructure / protocols
  { bucket: 'Services', name: /Service|Client|Manager|Repository|Store|Protocol/i },
  { bucket: 'Services', body: /\bprotocol\s+\w+\b|\bactor\s+\w+\b|URLSession|URLRequest/ },

  # Views — SwiftUI conformances (catch-all)
  { bucket: 'Views', body: /\bvar\s+body\s*:\s*some\s+View\b/ },
  { bucket: 'Views', name: /View$/ },
].freeze

# ─────────────────────────────────────────────────────────────────────────────
#  Utility helpers
# ─────────────────────────────────────────────────────────────────────────────

# Returns true if this .xcodeproj uses the Xcode 16+ FS-synchronized groups.
# These projects have almost no per-file entries — the whole source folder is
# tracked automatically by Xcode.
def fs_synchronized?
  File.read(PBXPROJ_PATH).include?('PBXFileSystemSynchronizedRootGroup')
end

# Classify a Swift file into an MVVM bucket by filename and content heuristics.
# Returns nil if the file cannot be classified.
def classify_swift(path)
  return nil if ROOT_ANCHORED.include?(File.basename(path))

  name    = File.basename(path, '.swift')
  content = File.read(path) rescue ''

  CLASSIFICATION_RULES.each do |rule|
    return rule[:bucket] if rule[:name] && name.match?(rule[:name])
    return rule[:bucket] if rule[:body] && content.match?(rule[:body])
  end

  nil
end

# Move src → dst, creating intermediate directories. Respects --dry-run.
def safe_mv(src, dst)
  rel_src = src.relative_path_from(PROJECT_ROOT)
  rel_dst = dst.relative_path_from(PROJECT_ROOT)
  if DRY_RUN
    Log.dry("mv #{rel_src}  →  #{rel_dst}")
  else
    FileUtils.mkdir_p(dst.dirname)
    FileUtils.mv(src.to_s, dst.to_s)
    Log.ok("Moved  #{src.basename}")
  end
end

# Create a directory, respecting --dry-run.
def safe_mkdir(path)
  rel = path.relative_path_from(PROJECT_ROOT)
  if DRY_RUN
    Log.dry("mkdir  #{rel}/") unless path.exist?
  elsif path.exist?
    Log.info("#{rel}/ already exists")
  else
    FileUtils.mkdir_p(path)
    Log.ok("Created  #{rel}/")
  end
end

# Remove a directory only when it is empty.
def safe_rmdir(path)
  return unless path.exist? && path.children.empty?
  if DRY_RUN
    Log.dry("rmdir  #{path.relative_path_from(PROJECT_ROOT)}/")
  else
    FileUtils.rmdir(path)
    Log.info("Removed empty  #{path.basename}/")
  end
end

# ─────────────────────────────────────────────────────────────────────────────
#  Phase 0 — Pre-flight
# ─────────────────────────────────────────────────────────────────────────────

def preflight
  Log.header('Phase 0 — Pre-flight Checks')

  unless XCODEPROJ
    Log.error('No .xcodeproj found in the current directory.')
    Log.info("Run this script from the folder that contains Pirless.xcodeproj")
    abort
  end
  Log.ok(".xcodeproj  : #{XCODEPROJ.basename}")

  unless SOURCE_ROOT.exist?
    Log.error("Source root #{SOURCE_ROOT} does not exist.")
    abort
  end
  Log.ok("Source root : #{SOURCE_ROOT.relative_path_from(PROJECT_ROOT)}/")

  if DRY_RUN
    Log.warn('--dry-run   : no files will be created, moved, or modified')
  else
    ts      = Time.now.strftime('%Y%m%d_%H%M%S')
    backup  = Pathname.new("#{XCODEPROJ}.bak_#{ts}")
    FileUtils.cp_r(XCODEPROJ.to_s, backup.to_s)
    Log.ok("Backup      : #{backup.basename}")
  end

  project_type = fs_synchronized? \
    ? 'PBXFileSystemSynchronizedRootGroup (Xcode 16+) — no xcodeproj surgery needed' \
    : 'Traditional PBXGroup — xcodeproj gem will be used'
  Log.ok("Type        : #{project_type}")
end

# ─────────────────────────────────────────────────────────────────────────────
#  Phase 1 — Create MVVM directory scaffold
# ─────────────────────────────────────────────────────────────────────────────

def create_scaffold
  Log.header('Phase 1 — Create MVVM Directory Scaffold')

  MVVM_DIRS.each { |d| safe_mkdir(SOURCE_ROOT / d) }
  FEATURE_MAP.values.uniq.each { |d| safe_mkdir(SOURCE_ROOT / d) }
end

# ─────────────────────────────────────────────────────────────────────────────
#  Phase 2 — Move Swift source files
# ─────────────────────────────────────────────────────────────────────────────

def move_source_files
  Log.header('Phase 2 — Move Swift Source Files')

  # 2a. Migrate Feature/ sub-directories → Views/{Details,Map,Shared}/
  FEATURE_MAP.each do |from_rel, to_rel|
    from_dir = SOURCE_ROOT / from_rel
    next unless from_dir.exist?

    from_dir.children.select { |f| f.extname == '.swift' }.each do |file|
      dest = SOURCE_ROOT / to_rel / file.basename
      if dest.exist?
        Log.warn("#{file.basename} already at destination — skipping")
        next
      end
      safe_mv(file, dest)
    end
  end

  # 2b. Classify any Swift files that are still outside an MVVM bucket.
  #     This handles files that were directly in the source root or in
  #     sub-folders not covered by FEATURE_MAP.
  Dir.glob("#{SOURCE_ROOT}/**/*.swift").each do |raw|
    path = Pathname.new(raw)
    rel  = path.relative_path_from(SOURCE_ROOT).to_s

    # Already in an MVVM bucket → skip
    next if MVVM_DIRS.any? { |d| rel.start_with?("#{d}/") }

    # Anchored root files (PirlessApp.swift, ContentView.swift) → skip
    next if ROOT_ANCHORED.include?(path.basename.to_s)

    bucket = classify_swift(path.to_s)
    unless bucket
      Log.warn("Could not classify #{rel} — left in place")
      next
    end

    # Views without a sub-folder go directly into Views/
    dest_dir  = SOURCE_ROOT / bucket
    dest_file = dest_dir / path.basename

    if dest_file.exist?
      Log.warn("#{dest_file.basename} already in #{bucket}/ — skipping")
      next
    end

    safe_mv(path, dest_file)
  end

  # 2c. Prune now-empty Feature/ directories
  FEATURE_MAP.keys.each { |rel| safe_rmdir(SOURCE_ROOT / rel) }
  safe_rmdir(SOURCE_ROOT / 'Features')
end

# ─────────────────────────────────────────────────────────────────────────────
#  Phase 3 — Migrate assets and resources into Resources/
# ─────────────────────────────────────────────────────────────────────────────

def migrate_resources
  Log.header('Phase 3 — Migrate Assets → Resources/')

  resources_dir = SOURCE_ROOT / 'Resources'
  safe_mkdir(resources_dir)

  # Collect resource candidates directly under SOURCE_ROOT
  candidates = SOURCE_ROOT.children.select do |child|
    name = child.basename.to_s
    next false if name.start_with?('.')        # hidden files
    next false if MVVM_DIRS.include?(name)     # MVVM buckets
    next false if name == 'Resources'           # already the target
    next false if ROOT_ANCHORED.include?(name)  # anchored Swift files

    ext = child.extname.empty? ? ".#{name.split('.').last}" : child.extname
    RESOURCE_EXTENSIONS.include?(ext)
  end

  if candidates.empty?
    Log.info('No loose resource files found at source root — nothing to migrate.')
    return
  end

  candidates.each do |item|
    dest = resources_dir / item.basename
    if dest.exist?
      Log.warn("#{item.basename} already in Resources/ — skipping")
      next
    end
    safe_mv(item, dest)
  end
end

# ─────────────────────────────────────────────────────────────────────────────
#  Phase 4a — PBXFileSystemSynchronizedRootGroup (Xcode 16+)
#             Nothing to rewrite — just report and validate.
# ─────────────────────────────────────────────────────────────────────────────

def report_fs_synced
  Log.header('Phase 4 — .xcodeproj Update (FS-Synchronized — Read-Only)')

  Log.ok('PBXFileSystemSynchronizedRootGroup detected.')
  Log.info('')
  Log.info('This project was created with Xcode 16+ and uses Filesystem')
  Log.info('Synchronized Groups. Xcode auto-tracks every file and folder')
  Log.info("under #{SOURCE_ROOT.basename}/ with a single lightweight entry in the")
  Log.info('.xcodeproj. No per-file PBXFileReference surgery is needed.')
  Log.info('')
  Log.info('What happens next time you open Xcode:')
  Log.info('  • All moved .swift files are found in their new MVVM locations')
  Log.info('  • They are added to the Sources build phase automatically')
  Log.info('  • The Navigator shows the new folder hierarchy as Xcode groups')
  Log.info('  • Assets in Resources/ are auto-compiled (no manual ref needed)')
  Log.info('')

  # Validate that the SynchronizedRootGroup still points at 'Pirless'
  pbx = File.read(PBXPROJ_PATH)
  if pbx.match?(/isa\s*=\s*PBXFileSystemSynchronizedRootGroup[^}]*path\s*=\s*Pirless\s*;/m)
    Log.ok('SynchronizedRootGroup anchor: path = Pirless ✓')
  else
    Log.warn('Could not confirm SynchronizedRootGroup anchor path. Inspect')
    Log.warn("#{PBXPROJ_PATH.relative_path_from(PROJECT_ROOT)} manually.")
  end

  Log.info('')
  Log.info('Expected Navigator tree after reopen:')
  Log.tree('Pirless/')
  Log.tree('├── Models/')
  Log.tree('├── Views/')
  Log.tree('│   ├── Details/')
  Log.tree('│   ├── Map/')
  Log.tree('│   └── Shared/')
  Log.tree('├── ViewModels/')
  Log.tree('├── Services/')
  Log.tree('├── Resources/')
  Log.tree('│   └── Assets.xcassets')
  Log.tree('├── ContentView.swift')
  Log.tree('└── PirlessApp.swift')
end

# ─────────────────────────────────────────────────────────────────────────────
#  Phase 4b — Traditional PBXGroup project
#             Full xcodeproj gem rewrite.
# ─────────────────────────────────────────────────────────────────────────────

def update_xcodeproj_traditional
  Log.header('Phase 4 — Rebuild Xcode Groups (xcodeproj gem)')

  begin
    require 'xcodeproj'
  rescue LoadError
    Log.error("The 'xcodeproj' gem is not installed.")
    Log.info("  Install it with:  gem install xcodeproj")
    Log.info("  Then rerun this script.")
    return
  end

  return Log.dry("Would open and rewrite #{XCODEPROJ.basename}") if DRY_RUN

  project     = Xcodeproj::Project.open(XCODEPROJ)
  target      = project.native_targets.first
  abort Log.error('No native target found') unless target

  src_phase   = target.source_build_phase
  res_phase   = target.resources_build_phase
  main_group  = project.main_group

  # ── Step 1: Remove dangling (red) file references ───────────────────────────
  Log.info('Scanning for dangling references...')
  dangling = 0

  [src_phase, res_phase].each do |phase|
    phase.files.to_a.each do |bf|
      real = begin; bf.file_ref&.real_path&.to_s; rescue; nil; end
      next if real && File.exist?(real)

      Log.warn("Removing dangling ref: #{bf.file_ref&.display_name || '(unknown)'}")
      phase.remove_build_file(bf)
      begin; bf.file_ref&.remove_from_project; rescue; end
      dangling += 1
    end
  end
  Log.ok("Dangling references removed: #{dangling}")

  # ── Step 2: Locate or create the top-level source group ─────────────────────
  src_group_name = SOURCE_ROOT.basename.to_s
  pirless_group  = main_group.groups.find { |g| g.path == src_group_name } ||
                   main_group.new_group(src_group_name, src_group_name)

  # ── Step 3: Drop the old Features/ group tree from the .xcodeproj ───────────
  old_features = pirless_group.groups.find { |g| g.path == 'Features' }
  if old_features
    old_features.recursive_children
               .select { |c| c.is_a?(Xcodeproj::Project::Object::PBXFileReference) }
               .each do |ref|
      src_phase.remove_file_reference(ref) rescue nil
      res_phase.remove_file_reference(ref) rescue nil
    end
    old_features.remove_from_project
    Log.ok('Removed stale Features/ group from .xcodeproj')
  end

  # ── Step 4: Rebuild MVVM group hierarchy ────────────────────────────────────
  MVVM_DIRS.each do |dir|
    disk_path = SOURCE_ROOT / dir
    next unless disk_path.exist?

    group = pirless_group.groups.find { |g| g.path == dir } ||
            pirless_group.new_group(dir, dir)

    if dir == 'Views'
      # Rebuild Views sub-groups
      %w[Details Map Shared].each do |sub|
        sub_disk = disk_path / sub
        next unless sub_disk.exist?

        sub_group = group.groups.find { |g| g.path == sub } ||
                    group.new_group(sub, sub)
        reindex_swift(sub_group, sub_disk, src_phase)
      end
      # Any .swift directly under Views/ (flat)
      reindex_swift(group, disk_path, src_phase, recurse: false)
    else
      reindex_swift(group, disk_path, src_phase)
    end
  end

  # ── Step 5: Re-index root-anchored Swift files ──────────────────────────────
  ROOT_ANCHORED.each do |filename|
    path = SOURCE_ROOT / filename
    next unless path.exist?
    already = pirless_group.files.any? do |f|
      (f.real_path.to_s rescue '') == path.to_s
    end
    next if already

    ref = pirless_group.new_file(path.to_s)
    src_phase.add_file_reference(ref)
    Log.ok("Re-indexed root file: #{filename}")
  end

  # ── Step 6: Add blue Folder Reference for Resources/ ────────────────────────
  resources_disk = SOURCE_ROOT / 'Resources'
  if resources_disk.exist?
    already_linked = main_group.children.any? do |c|
      c.respond_to?(:path) && c.path&.end_with?('Resources')
    end

    unless already_linked
      folder_ref = main_group.new_reference(resources_disk.to_s)
      # Force the type to 'folder' so Xcode treats it as a blue Folder Reference
      folder_ref.last_known_file_type = 'folder'
      folder_ref.source_tree          = '<group>'
      res_phase.add_file_reference(folder_ref)
      Log.ok('Added blue Folder Reference: Resources/')
    end
  end

  # ── Step 7: Save ─────────────────────────────────────────────────────────────
  project.save
  Log.ok('project.pbxproj saved cleanly')
end

# Add all .swift files in disk_dir to group + build phase, skipping duplicates.
def reindex_swift(group, disk_dir, build_phase, recurse: true)
  pattern = recurse ? "#{disk_dir}/**/*.swift" : "#{disk_dir}/*.swift"
  Dir.glob(pattern).each do |path|
    already = group.files.any? { |f| (f.real_path.to_s rescue '') == path }
    next if already

    ref = group.new_file(path)
    build_phase.add_file_reference(ref)
    Log.info("  Indexed: #{File.basename(path)}")
  end
end

# ─────────────────────────────────────────────────────────────────────────────
#  Entry point
# ─────────────────────────────────────────────────────────────────────────────

puts "\e[1;35m"
puts "  ╔══════════════════════════════════════════════════╗"
puts "  ║   Pirless  •  MVVM Reorganizer  v1.0             ║"
puts "  ║   Supports Xcode 16+ FS-Synchronized Groups      ║"
puts "  ╚══════════════════════════════════════════════════╝\e[0m"
puts

preflight
create_scaffold
move_source_files
migrate_resources

if fs_synchronized?
  report_fs_synced
else
  update_xcodeproj_traditional
end

puts
puts "\e[1;32m  ✓ Reorganization complete!\e[0m"
puts "  Reopen \e[1m#{XCODEPROJ&.basename}\e[0m in Xcode."
puts "  The new MVVM structure will appear in the Project Navigator."
puts
