//
//  Detail.swift
//  Pirless
//
//  Created by Muh. Naufal Fahri Salim on 8/13/26.
//

import SwiftUI

// MARK: - Design Tokens (from Figma reference)
//
// These accent colors come from the Figma design and don't map to an
// existing semantic system color (Color.primary/.secondary, etc.), so they
// are kept as raw values scoped to this file. Adding a named color set to
// Assets.xcassets (Pirless/Assets.xcassets) would be the cleaner long-term
// home for these tokens, but that file sits outside Features/Details, so it
// was intentionally left untouched — see the implementation report.

private let detailCardTitleColor = Color(
    red: 0x3d / 255.0,
    green: 0x4a / 255.0,
    blue: 0x44 / 255.0
)

private let detailCardValueColor = Color(
    red: 0x1b / 255.0,
    green: 0x1c / 255.0,
    blue: 0x1c / 255.0
)

private let detailLinkColor = Color(
    red: 0x1d / 255.0,
    green: 0x7a / 255.0,
    blue: 0x64 / 255.0
)

struct PointDetailView: View {

    let locationName: String

    /// PM2.5 value of the specific marker that was tapped on the map.
    /// Passed in by MapView (point.pm25) so this screen always reflects
    /// the selected point instead of a fixed sample value.
    let pm25: Double

    // MARK: - Mock Data
    // Temporary UI data.
    // Will later be replaced by project data/API.

    private let temperature: Double = 31
    private let humidity: Double = 78
    private let windSpeed: Double = 10
    private let vehiclesPerHour: Int = 1124

    private let vehicleBreakdown: [VehicleItem] = [

        VehicleItem(
            name: "Mobil",
            count: 200,
            systemImage: "car.fill",
            color: .green
        ),

        VehicleItem(
            name: "Motor",
            count: 900,
            systemImage: "motorcycle.fill",
            color: .purple
        ),

        VehicleItem(
            name: "Bus",
            count: 18,
            systemImage: "bus.fill",
            color: .blue
        ),

        VehicleItem(
            name: "Truk",
            count: 6,
            systemImage: "truck.box.fill",
            color: .orange
        )
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                sourceInformation

                PM25GaugeView(value: pm25)
                    .padding(.top, 32)

                metricsGrid

                historyLink

                vehicleBreakdownSection
                    .padding(.top, 24)

                footerNote
                    .padding(.top, 32)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(
            Color(.systemGroupedBackground)
        )
        // NOTE: Uses the native NavigationStack toolbar (system back button
        // + inline title) instead of the previous custom header, per the
        // Figma reference. This is purely a chrome/presentation change —
        // the push/pop navigation architecture from MapView
        // (NavigationStack + .navigationDestination(item:)) is unchanged.
        .navigationTitle(locationName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Source

private extension PointDetailView {

    var sourceInformation: some View {
        Text("Sumber: CCTV Jalan \(locationName)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
            .accessibilityLabel("Sumber data: CCTV Jalan \(locationName)")
    }
}

// MARK: - History Link

private extension PointDetailView {

    var historyLink: some View {
        HStack {
            Spacer(minLength: 0)

            Button {
                // TODO: Navigate to PM2.5 history.
            } label: {
                Text("Check History")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(detailLinkColor)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Check History")
            .accessibilityHint(
                "Membuka riwayat kualitas udara"
            )
        }
        .padding(.top, 8)
    }
}

// MARK: - Environmental Metrics

private extension PointDetailView {

    var metricsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(
                    .flexible(),
                    spacing: 8
                ),
                GridItem(
                    .flexible(),
                    spacing: 8
                )
            ],
            spacing: 8
        ) {

            MetricCard(
                title: "Temp",
                value: "\(Int(temperature))°C",
                systemImage: "thermometer.medium"
            )

            MetricCard(
                title: "Humidity",
                value: "\(Int(humidity))%",
                systemImage: "humidity"
            )

            MetricCard(
                title: "Wind",
                value: "\(Int(windSpeed)) km/h",
                systemImage: "wind"
            )

            MetricCard(
                title: "Vehicles",
                value: "\(vehiclesPerHour)/hr",
                systemImage: "car.fill"
            )
        }
        .padding(.top, 24)
    }
}

// MARK: - Vehicle Breakdown

private extension PointDetailView {

    /// Standalone heading + the compact list card, matching the Figma
    /// layout where the "Vehicle Breakdown" title sits outside the card.
    var vehicleBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text("Vehicle Breakdown")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(detailCardTitleColor)

            VehicleBreakdownView(
                vehicles: vehicleBreakdown
            )
        }
    }
}

// MARK: - Footer

private extension PointDetailView {

    var footerNote: some View {
        Text("Data diperbarui secara berkala untuk informasi yang lebih akurat")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Metric Card

private struct MetricCard: View {

    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            // MARK: Top Row
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(detailCardTitleColor)

                Spacer()

                Image(systemName: systemImage)
                    .font(
                        .system(
                            size: 18,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(.cyan)
            }

            Spacer()

            // MARK: Value
            Text(value)
                .font(.subheadline)
                .foregroundStyle(detailCardValueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(17)
        .frame(maxWidth: .infinity)
        .frame(height: 116)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
            .strokeBorder(
                Color(.separator).opacity(0.35),
                lineWidth: 1
            )
        )
        .shadow(
            color: .black.opacity(0.04),
            radius: 15,
            x: 0,
            y: 10
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PointDetailView(
            locationName: "Jalan Malioboro, Yogyakarta",
            pm25: 61
        )
    }
}

