//
//  MapView.swift
//  Pirless
//

import SwiftUI
import MapKit

struct MapView: View {

    @State private var viewModel = MapViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {

            ZStack {

                mapContent

                controls

                if viewModel.isLoading {
                    loadingView
                }
            }
            .ignoresSafeArea(edges: .top)

            .sheet(isPresented: $viewModel.showingSearch) {
                MapSearchView(
                    onSelectLocation: viewModel.moveCamera(to:distance:)
                )
                .presentationDragIndicator(.visible)
            }

            .navigationDestination(item: $viewModel.selectedPoint) { point in
                destinationView(for: point)
            }
        }

        .task {
            await viewModel.loadMapDataLoop()
        }
    }
}

// MARK: - Map Content

private extension MapView {

    var mapContent: some View {

        Map(position: Binding(
            get: { viewModel.cameraPosition },
            set: { viewModel.cameraPosition = $0 }
        )) {

            ForEach(viewModel.points) { point in

                PM25SpreadOverlay(
                    coordinate: point.coordinate,
                    directionDegrees: 90,
                    lengthMeters: 100,
                    visibility: viewModel.spreadVisibility
                )

                Annotation("", coordinate: point.coordinate) {

                    ZStack {

                        PM25SpreadAnimation(
                            directionDegrees: 90,
                            visibility: viewModel.spreadVisibility
                        )

                        PM25RadarPulse(
                            color: viewModel.markerColor(for: point),
                            scale: viewModel.radarScale,
                            visibility: viewModel.radarVisibility
                        )

                        marker(for: point)
                    }
                }
            }

            UserAnnotation()
        }

        .mapStyle(.standard)

        .onMapCameraChange(frequency: .onEnd) { context in
            viewModel.cameraDistance = context.camera.distance
        }
    }
}

// MARK: - Marker

private extension MapView {

    @ViewBuilder
    func marker(for point: TrafficPoint) -> some View {

        let currentPM25 = viewModel.pm25(for: point)
        let intervalMinutes = viewModel.pm25Interval(for: point)

        Button {
            viewModel.selectedPoint = point
        } label: {
            PM25MapMarker(value: currentPM25)
                .frame(width: 64, height: 64)
                .contentShape(Circle())
        }
        .buttonStyle(MarkerButtonStyle())
        .accessibilityLabel(point.locationName)
        .accessibilityValue(
            "Estimasi PM2.5 \(String(format: "%.2f", currentPM25)) µg/m³ selama \(intervalMinutes) menit"
        )
        .accessibilityHint("Ketuk untuk melihat detail kualitas udara")
    }
}

// MARK: - Navigation Destination

private extension MapView {

    @ViewBuilder
    func destinationView(for point: TrafficPoint) -> some View {

        if
            let traffic = viewModel.traffic(for: point),
            let weather = viewModel.weatherData[point.id]
        {
            PointDetailView(
                trafficPoint: point,
                traffic: traffic,
                weather: weather
            )
        } else {

            VStack(spacing: 12) {

                ProgressView()

                Text("Data belum tersedia")
                    .foregroundStyle(.secondary)

                if viewModel.vehicleTraffic.isEmpty {
                    Text("Data kendaraan belum diterima dari server.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Data CCTV untuk \(point.locationName) belum ditemukan.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
    }
}

// MARK: - Loading View

private extension MapView {

    var loadingView: some View {

        VStack {

            Spacer()

            HStack(spacing: 10) {

                ProgressView()

                Text("Memuat data...")
                    .font(.footnote.weight(.medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.thinMaterial, in: Capsule())

            Spacer()
                .frame(height: 80)
        }
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

            if viewModel.showingPM25Legend {

                PM25LegendView {
                    withAnimation(.easeOut(duration: 0.15)) {
                        viewModel.showingPM25Legend = false
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))

            } else {

                infoButton
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .safeAreaPadding(.top, 60)
    }

    var infoButton: some View {

        Button {
            withAnimation(.easeOut(duration: 0.15)) {
                viewModel.showingPM25Legend = true
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
        .accessibilityHint("Menampilkan informasi kategori PM2.5")
    }

    var searchButton: some View {

        Button {
            viewModel.showingSearch = true
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

private struct MarkerButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .opacity(configuration.isPressed ? 0.75 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    MapView()
}
