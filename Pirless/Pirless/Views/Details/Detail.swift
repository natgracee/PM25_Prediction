//
//  Detail.swift
//  Pirless
//
//  Created by Muh. Naufal Fahri Salim on 8/13/26.
//

import SwiftUI

struct PointDetailView: View {

    let locationName: String

    private let pm25: Double = 39
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

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                header

                sourceInformation

                PM25GaugeView(value: pm25)
                    .padding(.top, 32)

                historyButton
                metricsGrid

                VehicleBreakdownView(
                    vehicles: vehicleBreakdown
                )
                .padding(.top, 20)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(
            Color(.systemGroupedBackground)
        )
        .navigationBarBackButtonHidden()
    }
}


private extension PointDetailView {

    var header: some View {
        HStack(spacing: 16) {

            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(
                        .system(
                            size: 20,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(.primary)
                    .frame(
                        width: 56,
                        height: 56
                    )
                    .background(
                        .regularMaterial,
                        in: Circle()
                    )
            }
            .accessibilityLabel("Kembali")

            Text(locationName)
                .font(
                    .system(
                        size: 28,
                        weight: .bold
                    )
                )
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)
        }
        .padding(.top, 12)
    }
}

// MARK: - Source

private extension PointDetailView {

    var sourceInformation: some View {
        VStack(spacing: 4) {

            Text(
                "Sumber: CCTV Jalan \(locationName)"
            )
            .font(.system(size: 16))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

            Text("diperbarui 7 menit lalu")
                .font(.system(size: 14))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}

// MARK: - History

private extension PointDetailView {

    var historyButton: some View {
        Button {
            // TODO: Navigate to PM2.5 history.
        } label: {
            Text("Check History")
                .font(
                    .system(
                        size: 17,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.white)
                .frame(
                    width: 230,
                    height: 52
                )
                .background(
                    Color.green,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
        .padding(.top, 16)
        .accessibilityLabel("Check History")
        .accessibilityHint(
            "Membuka riwayat kualitas udara"
        )
    }
}

// MARK: - Environmental Metrics

private extension PointDetailView {

    var metricsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(
                    .flexible(),
                    spacing: 12
                ),
                GridItem(
                    .flexible(),
                    spacing: 12
                )
            ],
            spacing: 12
        ) {

            MetricCard(
                title: "Temp",
                value: "\(Int(temperature))°C",
                systemImage: "thermometer.medium",
                iconColor: .orange
            )

            MetricCard(
                title: "Humidity",
                value: "\(Int(humidity))%",
                systemImage: "humidity",
                iconColor: .blue
            )

            MetricCard(
                title: "Wind",
                value: "\(Int(windSpeed)) km/h",
                systemImage: "wind",
                iconColor: .cyan
            )

            MetricCard(
                title: "Vehicles",
                value: "\(vehiclesPerHour)/hr",
                systemImage: "car.fill",
                iconColor: .green
            )
        }
        .padding(.top, 24)
    }
}

// MARK: - Metric Card

private struct MetricCard: View {

    let title: String
    let value: String
    let systemImage: String
    let iconColor: Color

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            HStack {

                Text(title)
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)

                Spacer()

                Image(systemName: systemImage)
                    .font(
                        .system(
                            size: 24,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(iconColor)
            }

            Text(value)
                .font(
                    .system(
                        size: 30,
                        weight: .bold
                    )
                )
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 150)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PointDetailView(
            locationName: "Jalan Malioboro, Yogyakarta"
        )
    }
}
