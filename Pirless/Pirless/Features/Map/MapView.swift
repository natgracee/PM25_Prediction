//
//  MapView.swift
//  Pirless
//
//  Created by Muh. Naufal Fahri Salim on 8/13/26.
//


//
//  MapView.swift
//  Pirless
//
//  Created by Muh. Naufal Fahri Salim on 8/13/26.
//

import SwiftUI
import MapKit

struct MapView: View {

    // MARK: - State

    @State private var showingPM25Legend = false
    @State private var showingSearch = false
    @State private var cameraDistance: Double = 3000
    @State private var selectedPoint: MapPoint?

    // Owns the Map's camera. MapView remains the single source of truth for
    // camera position — MapSearchView never touches this directly, it only
    // reports back a coordinate via `onSelectLocation`.
    @State private var cameraPosition: MapCameraPosition = .automatic

    // MARK: - Sample Data

    private let points: [MapPoint] = [
        MapPoint(
            name: "Titik 1",
            latitude: -6.3015,
            longitude: 106.6520,
            pm25: 61,
            spreadDirection: 90
        ),
        MapPoint(
            name: "Titik 2",
            latitude: -6.3025,
            longitude: 106.6750,
            pm25: 61,
            spreadDirection: 90
        ),
        MapPoint(
            name: "Titik 3",
            latitude: -6.3300,
            longitude: 106.6700,
            pm25: 38,
            spreadDirection: 45
        )
    ]

    private var radarScale: CGFloat {
        switch cameraDistance {
        case 0...2_500:
            return 0.55

        case 2_500...5_000:
            return 0.75

        case 5_000...10_000:
            return 1.0

        case 10_000...25_000:
            return 1.15

        default:
            return 1.25
        }
    }

    private var radarVisibility: Double {
        switch cameraDistance {
        case 0...2_500:
            return 0.12

        case 2_500...5_000:
            return 0.18

        case 5_000...10_000:
            return 0.24

        case 10_000...25_000:
            return 0.18

        default:
            return 0.10
        }
    }

    // MARK: - Spread Visibility

    private var spreadVisibility: Double {
        switch cameraDistance {
        case 0...2_500:
            return 1.0

        case 2_500...5_000:
            return 0.65

        case 5_000...10_000:
            return 0.30

        case 10_000...25_000:
            return 0.10

        default:
            return 0.03
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                mapContent
                controls
            }
            .ignoresSafeArea(edges: .top)
            .sheet(isPresented: $showingSearch) {
                MapSearchView(onSelectLocation: moveCamera(to:distance:))
                    .presentationDragIndicator(.visible)
            }
            .navigationDestination(item: $selectedPoint) { point in
                PointDetailView(
                    locationName: point.name,
                    pm25: point.pm25
                )
            }
        }
    }
}

// MARK: - Map

private extension MapView {

    var mapContent: some View {
        Map(position: $cameraPosition) {
            ForEach(points) { point in

                PM25SpreadOverlay(
                    coordinate: point.coordinate,
                    directionDegrees: point.spreadDirection,
                    lengthMeters: 1200,
                    visibility: spreadVisibility
                )

                // NOTE: title is empty on purpose — no on-map text label.
                // Emptying it used to regress tap reliability, but that was
                // back when each point had 3 separate overlapping
                // Annotations and MapKit likely relied on the title to help
                // disambiguate hit-testing between them. Now that spread
                // animation, radar pulse, and the marker are combined into
                // a single Annotation per point (see note below), there's
                // no competing annotation at this coordinate anymore, so
                // the title is no longer needed for disambiguation.
                //
                // NOTE: spread animation, radar pulse, and the marker used
                // to each be their own separate `Annotation` at this same
                // coordinate — 3 MapKit annotation views stacked on top of
                // each other per point. That made MapKit's own annotation
                // hit-testing/selection ambiguous, independent of SwiftUI's
                // `.allowsHitTesting(false)` on the decorative layers.
                // They're now combined into a single Annotation with one
                // ZStack, so MapKit only ever tracks ONE annotation view
                // per point. Order inside the ZStack matters: marker must
                // stay last so it renders on top.
                Annotation(
                    "",
                    coordinate: point.coordinate
                ) {
                    ZStack {
                        PM25SpreadAnimation(
                            directionDegrees: point.spreadDirection,
                            visibility: spreadVisibility
                        )

                        PM25RadarPulse(
                            color: point.markerColor,
                            scale: radarScale,
                            visibility: radarVisibility
                        )

                        marker(for: point)
                    }
                }
            }

            UserAnnotation()
        }
        .mapStyle(.standard)
        // Changed from `.continuous` to `.onEnd`: continuous firing rebuilt
        // the entire annotation tree (radar pulse, spread animation, and
        // every marker) on almost every pixel of camera movement. That
        // churn is the most likely reason a marker felt like it needed to
        // "settle" after appearing/panning before it could be tapped.
        // `.onEnd` only updates once a gesture finishes, so annotation
        // views stay stable while the user is actively interacting.
        .onMapCameraChange(frequency: .onEnd) { context in
            cameraDistance = context.camera.distance
        }
    }

    /// Recenters AND zooms the map camera onto a coordinate picked from
    /// search results. Search must always bring the result into focus,
    /// even if it was already technically visible in a zoomed-out
    /// viewport (e.g. world view) — so this always applies the given
    /// `distance` rather than keeping whatever `cameraDistance` the user
    /// happened to be at. `distance` comes from MapSearchView, scaled to
    /// how administratively specific the picked result is (street vs.
    /// kecamatan vs. kota vs. provinsi/negara), matching Apple Maps'
    /// behavior of zooming tighter for more specific results.
    /// `cameraDistance` is updated to match so `.onMapCameraChange` and
    /// the radar/spread visibility calculations stay in sync with the
    /// new zoom level.
    func moveCamera(
        to coordinate: CLLocationCoordinate2D,
        distance: Double
    ) {
        withAnimation {
            cameraDistance = distance
            cameraPosition = .camera(
                MapCamera(
                    centerCoordinate: coordinate,
                    distance: distance
                )
            )
        }
    }

    @ViewBuilder
    func marker(for point: MapPoint) -> some View {
        Button {
            selectedPoint = point
        } label: {
            PM25MapMarker(value: point.pm25)
                .frame(width: 64, height: 64)
                .contentShape(Circle())
        }
        .buttonStyle(MarkerButtonStyle())
        .accessibilityLabel(point.name)
        .accessibilityValue(point.accessibilityDescription)
        .accessibilityHint(
            "Ketuk untuk melihat detail kualitas udara"
        )
    }
}

// MARK: - Controls

private extension MapView {

    var controls: some View {
        VStack {
            topControls

            Spacer()

            searchButton
        }
    }

    // NOTE: The Figma reference places the info/legend button at the
    // top-LEADING edge of the screen (not trailing, as the previous
    // implementation had it). Swapped the Spacer position to match.
    var topControls: some View {
        HStack {
            if showingPM25Legend {
                PM25LegendView {
                    withAnimation(.easeOut(duration: 0.15)) {
                        showingPM25Legend = false
                    }
                }
                .transition(
                    .opacity
                        .combined(
                            with: .scale(scale: 0.95)
                        )
                )
            } else {
                infoButton
                    .transition(
                        .opacity
                            .combined(
                                with: .scale(scale: 0.95)
                            )
                    )
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .safeAreaPadding(.top, 60)
    }

    // NOTE: Uses the system Liquid Glass material (`.glassEffect()`) instead
    // of `.thinMaterial`, matching the "Liquid Glass - Regular - Medium"
    // component used throughout the Figma reference. The project's
    // deployment target (iOS 26.5) supports this API directly.
    var infoButton: some View {
        Button {
            withAnimation(.easeOut(duration: 0.15)) {
                showingPM25Legend = true
            }
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .glassEffect(in: Circle())
        .accessibilityLabel("Informasi PM2.5")
        .accessibilityHint(
            "Menampilkan informasi kategori PM2.5"
        )
    }

    var searchButton: some View {
        Button {
            showingSearch = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.body.weight(.medium))

                Text("Search Area")
                    .font(.body)

                Spacer()

                Image(systemName: "mic.fill")
                    .font(.body)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .frame(minHeight: 52)
        }
        .buttonStyle(.plain)
        .glassEffect(in: Capsule())
        .accessibilityLabel("Search Area")
        .accessibilityHint("Mencari lokasi")
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
}

// MARK: - Marker Button Style

/// Gives the marker a visible pressed state (slightly scaled down and
/// dimmed) so it's clear a tap registered, instead of `.plain`'s lack of
/// any feedback. Kept lightweight on purpose — the hit-testing/annotation
/// churn fixed earlier in this file is unrelated to this purely visual
/// change.
private struct MarkerButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .opacity(configuration.isPressed ? 0.75 : 1.0)
            .animation(
                .easeOut(duration: 0.12),
                value: configuration.isPressed
            )
    }
}

// MARK: - Map Point

private struct MapPoint: Identifiable, Hashable {

    let id = UUID()

    let name: String
    let latitude: Double
    let longitude: Double
    let pm25: Double
    let spreadDirection: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude
        )
    }

    var markerColor: Color {
        switch pm25 {
        case 0...35:
            return .green

        case 36...55:
            return .yellow

        default:
            return .red
        }
    }
    var accessibilityDescription: String {
        "PM2.5 \(pm25.formatted(.number.precision(.fractionLength(0)))) mikrogram per meter kubik"
    }
}

// MARK: - Preview

#Preview {
    MapView()
}
