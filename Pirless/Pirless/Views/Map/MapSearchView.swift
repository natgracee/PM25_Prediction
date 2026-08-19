//
//  MapSearchView.swift
//  Pirless
//
//  Created by M. TAQWA ADDARI on 17/08/26.
//


import SwiftUI
import MapKit

struct MapSearchView: View {

    // MARK: - Input

    /// Reports the coordinate AND the target camera distance for the
    /// location the user picked, so MapView (which owns the map camera)
    /// can recenter and zoom onto it. The distance is derived from how
    /// administratively specific the result is (street vs. kecamatan vs.
    /// kota vs. provinsi/negara) — see `SearchResult.makeCameraDistance`.
    /// MapSearchView never touches the map camera itself.
    let onSelectLocation: (CLLocationCoordinate2D, Double) -> Void

    // MARK: - State

    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var results: [SearchResult] = []
    @State private var isSearching = false

    @FocusState private var searchFieldFocused: Bool

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                header

                searchResults

                Spacer()

                searchBar
            }
        }
        .task(id: searchText) {
            await performSearch()
        }
        .onAppear {
            searchFieldFocused = true
        }
    }
}

// MARK: - Background

private extension MapSearchView {

    var background: some View {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
    }
}

// MARK: - Header

private extension MapSearchView {

    var header: some View {
        HStack {
            Text("Map Locations")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }
}

// MARK: - Results

private extension MapSearchView {

    var searchResults: some View {
        VStack(spacing: 0) {

            if isSearching {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)

            } else if results.isEmpty && !searchText.isEmpty {
                emptyState

            } else if results.isEmpty {
                EmptyView()

            } else {
                resultsCard
            }
        }
        .padding(.horizontal, 16)
    }

    var resultsCard: some View {
        VStack(spacing: 0) {

            ForEach(results) { result in
                resultRow(result)

                if result.id != results.last?.id {
                    Divider()
                        .padding(.leading, 44)
                }
            }

            if !results.isEmpty {
                Button {
                    // Additional results can be implemented later.
                } label: {
                    HStack {
                        Text("More results")
                            .font(.body.weight(.semibold))

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
                .accessibilityLabel("More results")
            }
        }
        .background(
            .background,
            in: RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
        )
    }

    @ViewBuilder
    func resultRow(_ result: SearchResult) -> some View {
        Button {
            select(result)
        } label: {
            HStack(alignment: .top, spacing: 16) {

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.secondary)
                    .frame(
                        width: 28,
                        height: 28
                    )

                VStack(alignment: .leading, spacing: 4) {

                    Text(result.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)

                    if !result.subtitle.isEmpty {
                        Text(result.subtitle)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Pilih lokasi ini")
    }

    var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "mappin.slash")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("No locations found")
                .font(.headline)

            Text("Try another search.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Search Bar

private extension MapSearchView {

    var searchBar: some View {
        HStack(spacing: 10) {

            Image(systemName: "magnifyingglass")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.primary)

            TextField(
                "Search Area",
                text: $searchText
            )
            .font(.body)
            .focused($searchFieldFocused)
            .submitLabel(.search)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchFieldFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Hapus pencarian")
            }
        }
        .padding(.horizontal, 20)
        .frame(minHeight: 56)
        .background(
            .background,
            in: Capsule()
        )
        .overlay {
            Capsule()
                .stroke(
                    Color.secondary.opacity(0.12),
                    lineWidth: 1
                )
        }
        .padding(.leading, 16)
        .padding(.trailing, 84)
        .padding(.bottom, 12)
        .overlay(alignment: .trailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(
                        width: 56,
                        height: 56
                    )
                    .background(
                        .background,
                        in: Circle()
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Tutup pencarian")
            .padding(.trailing, 16)
            .padding(.bottom, 12)
        }
    }
}

// MARK: - Search

private extension MapSearchView {

    func performSearch() async {

        let query = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !query.isEmpty else {
            results = []
            isSearching = false
            return
        }

        isSearching = true

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        do {
            let response = try await MKLocalSearch(
                request: request
            )
            .start()

            guard !Task.isCancelled else {
                return
            }

            results = response.mapItems
                .prefix(5)
                .map(SearchResult.init)

            isSearching = false

        } catch {
            guard !Task.isCancelled else {
                return
            }

            results = []
            isSearching = false
        }
    }
    
    func loadMoreResults() async {

        let query = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !query.isEmpty else {
            return
        }

        isSearching = true

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        do {
            let response = try await MKLocalSearch(
                request: request
            )
            .start()

            guard !Task.isCancelled else {
                return
            }

            let newResults = response.mapItems
                .map(SearchResult.init)

            results = Array(
                newResults.prefix(15)
            )

            isSearching = false

        } catch {
            guard !Task.isCancelled else {
                return
            }

            isSearching = false
        }
    }

    func select(_ result: SearchResult) {
        onSelectLocation(result.coordinate, result.cameraDistance)
        dismiss()
    }
}

// MARK: - Search Result

private struct SearchResult: Identifiable {

    let id: String
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D

    /// Target camera distance (meters) for this result, scaled to how
    /// administratively specific it is — matches how Apple Maps zooms
    /// tighter for a street address than for a city or province.
    let cameraDistance: Double

    init(mapItem: MKMapItem) {
        // `mapItem.location` is non-optional in this SDK (unlike the
        // deprecated `placemark`), so no fallback/optional-chaining needed.
        let coordinate = mapItem.location.coordinate

        self.id = "\(mapItem.name ?? "")-\(coordinate.latitude)-\(coordinate.longitude)"
        self.title = mapItem.name ?? "Unknown Location"
        self.subtitle = Self.makeSubtitle(
            from: mapItem.placemark
        )
        self.coordinate = coordinate
        self.cameraDistance = Self.makeCameraDistance(
            from: mapItem.placemark
        )
    }

    private static func makeSubtitle(
        from placemark: CLPlacemark
    ) -> String {

        if let area = placemark.locality,
           let country = placemark.country {
            return "\(area), \(country)"
        }

        if let area = placemark.locality {
            return area
        }

        if let country = placemark.country {
            return country
        }

        return ""
    }

    /// Classifies the result's administrative scale from the most specific
    /// placemark field that's actually populated, then maps that scale to
    /// a camera distance — the same "zoom to match what was searched"
    /// behavior Apple Maps uses. Checked from most to least specific:
    /// street/thoroughfare → kecamatan (subLocality) → kota (locality) →
    /// provinsi (administrativeArea) → negara (country) → unknown fallback.
    private static func makeCameraDistance(
        from placemark: CLPlacemark
    ) -> Double {

        if placemark.thoroughfare != nil {
            return 1_200
        }

        if placemark.subLocality != nil {
            return 4_000
        }

        if placemark.locality != nil {
            return 18_000
        }

        if placemark.administrativeArea != nil {
            return 150_000
        }

        if placemark.country != nil {
            return 900_000
        }

        return 3_000
    }
}

// MARK: - Preview

#Preview {
    MapSearchView(onSelectLocation: { _, _ in })
}

