#!/usr/bin/env ruby
# frozen_string_literal: true

# =============================================================================
# mvvm_organizer.rb — Xcode MVVM Project Structure Organizer
# Compatible with Ruby 2.6+ (system Ruby on macOS)
# =============================================================================
#
# USAGE (run from the directory that contains your .xcodeproj):
#   ruby mvvm_organizer.rb              # live run
#   ruby mvvm_organizer.rb --dry-run    # preview only, zero writes
#   ruby mvvm_organizer.rb --project path/to/MyApp.xcodeproj
# =============================================================================

require 'xcodeproj'
require 'fileutils'
require 'find'
require 'pathname'
require 'optparse'

# ─── ANSI colour helpers (Ruby 2.6 compatible) ───────────────────────────────
module C
  RESET = "\e[0m"

  def self.green(s)
    $stdout.tty? ? "\e[32m#{s}#{RESET}" : s
  end

  def self.yellow(s)
    $stdout.tty? ? "\e[33m#{s}#{RESET}" : s
  end

  def self.red(s)
    $stdout.tty? ? "\e[31m#{s}#{RESET}" : s
  end

  def self.cyan(s)
    $stdout.tty? ? "\e[36m#{s}#{RESET}" : s
  end

  def self.bold(s)
    $stdout.tty? ? "\e[1m#{s}#{RESET}" : s
  end

  def self.dim(s)
    $stdout.tty? ? "\e[2m#{s}#{RESET}" : s
  end
end

# ─── MVVM classification rules (content-based, ordered most→least specific) ──
CONTENT_RULES = [
  {
    layer: 'ViewModels',
    patterns: [
      /:\s*(ObservableObject|ViewModel)\b/,
      /@\s*Observable\b/,
      /@Published\b/,
      /\bclass\s+\w*ViewModel\b/
    ]
  },
  {
    layer: 'Services',
    patterns: [
      /\bprotocol\s+\w*(Service|Repository|Client|Provider|Manager)\b/i,
      /\bclass\s+\w*(Service|Repository|Client|Provider|Manager)\b/i,
      /\bURLSession\b/,
      /\bURLRequest\b/,
      /\basync\s+func\s+fetch\b/
    ]
  },
  {
    layer: 'Views',
    patterns: [
      /:\s*View\b/,
      /\bsome\s+View\b/,
      /\bUIViewController\b/,
      /\bUIView\b/,
      /\bNSViewController\b/
    ]
  },
  {
    layer: 'Models',
    patterns: [
      /\bstruct\b/,
      /\bclass\b/,
      /\benum\b/,
      /\bactor\b/
    ]
  }
].freeze

# Filename-based fallback for empty / stub files
NAME_TO_LAYER = {
  'ViewModels' => /ViewModel$/i,
  'Services'   => /(Service|Client|Repository|Manager|Provider|API)$/i,
  'Views'      => /(View|Screen|Page|Detail|Map|List|Cell|Controller|Scene)$/i
}.freeze

# Extensions treated as raw resources moved into Resources/
RESOURCE_EXTENSIONS = %w[.json .mp3 .mp4 .wav .aiff .html .css
                         .strings .stringsdict .xcstrings].freeze

# ─── CLI option parsing ───────────────────────────────────────────────────────
options = { dry_run: false, project_path: nil }

OptionParser.new do |opts|
  opts.banner = 'Usage: ruby mvvm_organizer.rb [--dry-run] [--project PATH]'
  opts.on('--dry-run', 'Preview all changes without writing anything') do
    options[:dry_run] = true
  end
  opts.on('--project PATH', 'Explicit path to .xcodeproj file') do |p|
    options[:project_path] = p
  end
  opts.on('-h', '--help', 'Show this message') { puts opts; exit }
end.parse!

dry_run = options[:dry_run]

puts C.yellow("\n⚠  DRY-RUN MODE — zero files will be modified\n") if dry_run

# ─── Locate .xcodeproj ───────────────────────────────────────────────────────
project_path = options[:project_path] || Dir.glob('*.xcodeproj').first

unless project_path
  abort C.red("✖  No .xcodeproj found in current directory.\n" \
              "   cd into your project root or pass --project PATH")
end

abort C.red("✖  Not found: #{project_path}") unless File.directory?(project_path)

pbxproj_path = File.join(project_path, 'project.pbxproj')
abort C.red("✖  project.pbxproj missing inside #{project_path}") unless File.exist?(pbxproj_path)

# ─── Backup project.pbxproj ──────────────────────────────────────────────────
backup_path = "#{pbxproj_path}.bak_#{Time.now.strftime('%Y%m%d_%H%M%S')}"
unless dry_run
  FileUtils.cp(pbxproj_path, backup_path)
  puts C.dim("  Backup → #{backup_path}\n")
end

# ─── Load project ─────────────────────────────────────────────────────────────
project      = Xcodeproj::Project.open(project_path)
project_root = File.dirname(File.expand_path(project_path))
main_target  = project.targets.reject(&:test_target_type?).first

abort C.red('✖  No non-test target found in the project.') unless main_target

app_name   = File.basename(project_path, '.xcodeproj')
source_dir = File.join(project_root, app_name)

abort C.red("✖  App source directory not found: #{source_dir}") unless File.directory?(source_dir)

puts C.bold("=== Xcode MVVM Organizer ===")
puts "  Project : #{project_path}"
puts "  Target  : #{C.cyan(main_target.name)}"
puts "  Source  : #{source_dir}"

# ─── Detect PBXFileSystemSynchronizedRootGroup (Xcode 15+) ───────────────────
sync_groups     = project.objects.select { |o| o.isa == 'PBXFileSystemSynchronizedRootGroup' }
using_sync_group = !sync_groups.empty?

if using_sync_group
  puts C.cyan("\n  ℹ  PBXFileSystemSynchronizedRootGroup detected (Xcode 15+ auto-sync).")
  puts C.cyan("     File moves on disk auto-reflect in Xcode. No .xcodeproj edits needed.")
end

# ─── Helper: relative path for clean log output ───────────────────────────────
def rel(path, base)
  Pathname.new(path).relative_path_from(Pathname.new(base)).to_s
end

# ─── STEP 1 — Discover and classify Swift files ───────────────────────────────
puts C.bold("\n[1/3] Classifying Swift files...")

swift_files = []
Find.find(source_dir) do |path|
  Find.prune if File.basename(path).start_with?('.') || path.include?('DerivedData')
  swift_files << path if File.file?(path) && path.end_with?('.swift')
end

classification = {}

swift_files.each do |path|
  basename = File.basename(path, '.swift')
  content  = File.read(path).encode('UTF-8', invalid: :replace, undef: :replace, replace: '')

  # App entry point stays at source root
  if basename.end_with?('App')
    classification[path] = :app
    next
  end

  matched_layer = nil

  # Content-based detection (reliable for non-empty files)
  unless content.strip.empty?
    CONTENT_RULES.each do |rule|
      if rule[:patterns].any? { |pat| content.match?(pat) }
        matched_layer = rule[:layer].to_sym
        break
      end
    end
  end

  # Name-based fallback for empty stubs
  unless matched_layer
    NAME_TO_LAYER.each do |layer, pattern|
      if basename.match?(pattern)
        matched_layer = layer.to_sym
        break
      end
    end
  end

  matched_layer ||= :Models
  classification[path] = matched_layer
end

# Display classification results
grouped = classification.group_by { |_, layer| layer }
grouped.each do |layer, entries|
  label = layer == :app ? C.dim('app root') : C.cyan(layer.to_s)
  names = entries.map { |p, _| File.basename(p) }.join(', ')
  puts "  #{label.ljust(22)}  #{names}"
end

# ─── STEP 2 — Move files into MVVM hierarchy ─────────────────────────────────
puts C.bold("\n[2/3] Moving files into MVVM hierarchy...")

target_dirs = {
  Models:     File.join(source_dir, 'Models'),
  Views:      File.join(source_dir, 'Views'),
  ViewModels: File.join(source_dir, 'ViewModels'),
  Services:   File.join(source_dir, 'Services')
}

move_ops = []

classification.each do |src, layer|
  next if layer == :app

  dest_dir = target_dirs[layer]
  dst      = File.join(dest_dir, File.basename(src))

  next if File.expand_path(src) == File.expand_path(dst)

  move_ops << { from: src, to: dst, dir: dest_dir }
end

if move_ops.empty?
  puts C.dim('  All files are already in their correct MVVM locations.')
else
  move_ops.each do |op|
    tag = dry_run ? C.dim('[DRY] mv') : C.green('mv')
    puts "  #{tag}  #{rel(op[:from], project_root)}  →  #{rel(op[:to], project_root)}"

    unless dry_run
      FileUtils.mkdir_p(op[:dir])
      FileUtils.mv(op[:from], op[:to])
    end
  end
end

# Create ViewModels/ even if empty (reserved for future use)
unless dry_run
  FileUtils.mkdir_p(target_dirs[:ViewModels])
end

# ─── Prune empty directories (e.g. old Features/) ────────────────────────────
puts C.bold("\n       Pruning stale empty directories...")

pruned_any = false
all_dirs   = []
Find.find(source_dir) { |p| all_dirs << p if File.directory?(p) }

# Sort deepest-first so children are removed before parents
all_dirs.sort_by { |p| -p.length }.each do |dir|
  next if dir == source_dir
  next if target_dirs.values.include?(dir)

  entries = Dir.entries(dir) - %w[. ..]
  if entries.empty?
    tag = dry_run ? C.dim('[DRY] rmdir') : C.red('rmdir')
    puts "  #{tag}  #{rel(dir, project_root)}"
    FileUtils.rmdir(dir) unless dry_run
    pruned_any = true
  end
end

puts C.dim('  No empty directories to prune.') unless pruned_any

# ─── STEP 3 — Assets & Resources migration ───────────────────────────────────
puts C.bold("\n[3/3] Assets & Resources...")

resources_dir = File.join(source_dir, 'Resources')

raw_assets = []
Find.find(source_dir) do |path|
  Find.prune if File.basename(path).start_with?('.')
  next unless File.file?(path)
  ext = File.extname(path).downcase
  raw_assets << path if RESOURCE_EXTENSIONS.include?(ext)
end

if raw_assets.empty?
  puts C.dim('  No raw resource files found. Skipping Resources migration.')
else
  FileUtils.mkdir_p(resources_dir) unless dry_run

  raw_assets.each do |asset|
    dst = File.join(resources_dir, File.basename(asset))
    next if File.expand_path(asset) == File.expand_path(dst)

    tag = dry_run ? C.dim('[DRY] mv') : C.green('mv')
    puts "  #{tag}  #{rel(asset, project_root)}  →  #{rel(dst, project_root)}"
    FileUtils.mv(asset, dst) unless dry_run
  end
end

# ─── xcodeproj edits (traditional PBXGroup projects only) ────────────────────
if using_sync_group
  puts C.cyan("\n  ℹ  Sync-group project — skipping manual group rewrite.")
  puts C.cyan("     Xcode auto-detects the new layout on next open/build.")
else
  puts C.bold("\n  Rebuilding Xcode groups to match MVVM layout...")

  app_group = project.main_group.find_subpath(app_name, false)

  if app_group.nil?
    puts C.red("  ✖  Group '#{app_name}' not found — skipping group rebuild.")
  else
    # Remove dangling references (red files)
    stale = project.objects.select do |obj|
      next false unless obj.isa == 'PBXFileReference'
      begin
        abs = File.expand_path(obj.real_path.to_s, project_root)
        !File.exist?(abs)
      rescue StandardError
        false
      end
    end

    stale.each do |ref|
      tag = dry_run ? C.dim('[DRY] remove stale') : C.red('remove stale')
      puts "  #{tag}  #{ref.path}"
      ref.remove_from_project unless dry_run
    end

    unless dry_run
      # Remove pre-existing MVVM groups to avoid duplicates
      %w[Models Views ViewModels Services Features].each do |g|
        existing = app_group.find_subpath(g, false)
        existing&.remove_from_project
      end

      # Recreate MVVM groups
      target_dirs.each do |layer, dir|
        next unless File.directory?(dir)

        swift_in_dir = Dir.glob(File.join(dir, '**', '*.swift')).sort
        group = app_group.new_group(layer.to_s, layer.to_s)

        swift_in_dir.each do |f|
          file_ref = group.new_file(f)
          main_target.source_build_phase.add_file_reference(file_ref, true)
        end

        puts "  #{C.green('group')}  #{layer} (#{swift_in_dir.count} files)"
      end

      # Wire Resources/ as a blue Folder Reference if it exists
      if File.directory?(resources_dir)
        existing_res = app_group.find_subpath('Resources', false)
        existing_res&.remove_from_project

        res_ref = project.main_group.new_reference(resources_dir)
        res_ref.last_known_file_type = 'folder'
        res_ref.source_tree          = 'SOURCE_ROOT'
        res_ref.path                 = "#{app_name}/Resources"

        main_target.resources_build_phase.add_file_reference(res_ref)
        puts "  #{C.green('folder-ref')}  Resources/ (blue folder)"
      end

      project.save
      puts C.green("  ✔  project.pbxproj saved.")
    end
  end
end

# ─── Summary ──────────────────────────────────────────────────────────────────
puts C.bold("\n═══ Done ═══")

if dry_run
  puts C.yellow("Dry run complete. Re-run without --dry-run to apply changes.")
else
  puts C.green("✔  MVVM structure applied.")
  puts C.green("✔  Backup: #{backup_path}")
  puts ""
  puts "  Next steps:"
  puts "  1. Close and reopen #{project_path} in Xcode"
  if using_sync_group
    puts "  2. New MVVM folders appear automatically in the Navigator"
  else
    puts "  2. Verify new MVVM groups in the Project Navigator"
  end
  puts "  3. Press ⌘B — should build with zero errors"
end
