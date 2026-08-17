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
                MapSearchView()
                    .presentationDragIndicator(.visible)
            }
            .navigationDestination(item: $selectedPoint) { point in
                PointDetailView(
                    locationName: point.name
                )
            }
        }
    }
}

// MARK: - Map

private extension MapView {

    var mapContent: some View {
        Map {
            ForEach(points) { point in

                PM25SpreadOverlay(
                    coordinate: point.coordinate,
                    directionDegrees: point.spreadDirection,
                    lengthMeters: 1200,
                    visibility: spreadVisibility
                )

                PM25SpreadAnimation(
                    coordinate: point.coordinate,
                    directionDegrees: point.spreadDirection,
                    visibility: spreadVisibility
                )

                PM25RadarPulse(
                    coordinate: point.coordinate,
                    color: point.markerColor,
                    scale: radarScale,
                    visibility: radarVisibility
                )

                Annotation(
                    point.name,
                    coordinate: point.coordinate
                ) {
                    marker(for: point)
                }
            }

            UserAnnotation()
        }
        .mapStyle(.standard)
        .onMapCameraChange(frequency: .continuous) { context in
            cameraDistance = context.camera.distance
        }
    }

    @ViewBuilder
    func marker(for point: MapPoint) -> some View {
        Button {
            selectedPoint = point
        } label: {
            PM25MapMarker(value: point.pm25)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
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

    var topControls: some View {
        HStack {
            Spacer()

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
        }
        .padding(.horizontal, 16)
        .safeAreaPadding(.top, 60)
    }

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
                .background(
                    .thinMaterial,
                    in: Circle()
                )
        }
        .buttonStyle(.plain)
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
            .background(
                .thinMaterial,
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Search Area")
        .accessibilityHint("Mencari lokasi")
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
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
