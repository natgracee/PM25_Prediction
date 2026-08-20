//
//  PointDetailView.swift
//  Pirless
//

import SwiftUI

struct PointDetailView: View {

    // MARK: - Data

    let trafficPoint: TrafficPoint
    let traffic: VehicleTrafficResponse
    let weather: WeatherResponse

    // MARK: - Environment

    @Environment(\.dismiss)
    private var dismiss

    // MARK: - Vehicle

    /// Kendaraan HANYA berasal dari interval traffic
    /// yang sedang ditampilkan.
    ///
    /// Tidak mengambil data dari interval sebelumnya.
    private var vehicleCount: VehicleCount {
        traffic.volumeKendaraan.asVehicleCount
    }

    // MARK: - Interval

    /// Durasi interval yang dikirim oleh API.
    ///
    /// API sudah mengirim data per 7 menit.
    /// Jadi setiap response merupakan satu periode
    /// pengamatan tersendiri.
    private var intervalText: String {
        "\(traffic.intervalMenit) menit"
    }

    // MARK: - PM2.5

    /// PM2.5 untuk SATU interval traffic.
    ///
    /// Penting:
    /// - Tidak mengambil history.
    /// - Tidak menjumlahkan interval sebelumnya.
    /// - Tidak mengakumulasi PM2.5.
    /// - Kendaraan hanya berasal dari traffic saat ini.
    /// - Durasi hanya berasal dari interval API saat ini.
    private var pm25: Double {
        let safeIntervalMinutes = max(
            traffic.intervalMenit,
            1
        )

        return trafficPoint.predictedPM25C(
            vehicleCount: vehicleCount,
            windSpeed: weather.current.windSpeed10m,
            intervalMinutes: safeIntervalMinutes
        )
    }

    private var pm25Level: TrafficPoint.PM25Level {
        TrafficPoint.level(for: pm25)
    }

    private var pm25Text: String {
        String(
            format: "%.2f µg/m³",
            pm25
        )
    }

    // MARK: - Body

    var body: some View {
        ScrollView {

            VStack(spacing: 0) {

                header

                pm25Section

                historyButton

                metricsGrid

                vehicleBreakdownSection
                    .padding(.top, 20)

                footerNote
                    .padding(.top, 32)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(
            Color(
                .systemGroupedBackground
            )
        )
        .navigationBarBackButtonHidden()
    }
}

// MARK: - Header

private extension PointDetailView {

    var header: some View {

        HStack(spacing: 16) {

            Button {

                dismiss()

            } label: {

                Image(
                    systemName:
                        "chevron.left"
                )
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
            .accessibilityLabel(
                "Kembali"
            )

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text(
                    trafficPoint.locationName
                )
                .font(
                    .system(
                        size: 24,
                        weight: .bold
                    )
                )
                .lineLimit(1)

                Text(
                    "CCTV / Traffic Point"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.top, 12)
    }
}

// MARK: - PM2.5

private extension PointDetailView {

    var pm25Section: some View {

        VStack(spacing: 12) {

            Text("PM2.5")
                .font(
                    .system(
                        size: 18,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    .secondary
                )

            Text(pm25Text)
                .font(
                    .system(
                        size: 38,
                        weight: .bold
                    )
                )

            Text(
                pm25Level.title
            )
            .font(
                .system(
                    size: 17,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                pm25Color
            )

            Text(
                "Estimasi untuk \(traffic.intervalMenit) menit data CCTV"
            )
            .font(.caption)
            .foregroundStyle(
                .secondary
            )

            Text(
                "\(traffic.mulai) – \(traffic.selesai)"
            )
            .font(.caption2)
            .foregroundStyle(
                .secondary
            )

            Text(
                "Ruas model: \(Int(trafficPoint.roadLengthMeters)) m"
            )
            .font(.caption2)
            .foregroundStyle(
                .secondary
            )
        }
        .frame(
            maxWidth: .infinity
        )
        .padding(
            .vertical,
            24
        )
        .background(
            Color(
                .secondarySystemGroupedBackground
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
        .padding(.top, 24)
    }

    var pm25Color: Color {

        switch pm25Level {

        case .good:
            return .green

        case .moderate:
            return .yellow

        case .unhealthy:
            return .red
        }
    }
}

// MARK: - History

private extension PointDetailView {

    var historyButton: some View {

        NavigationLink {

            HistoryView(
                trafficPoint:
                    trafficPoint
            )

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
    }
}

// MARK: - Metrics

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
                value: temperatureText,
                systemImage:
                    "thermometer.medium",
                iconColor: .orange
            )

            MetricCard(
                title: "Humidity",
                value: humidityText,
                systemImage:
                    "humidity",
                iconColor: .blue
            )

            MetricCard(
                title: "Wind",
                value: windText,
                systemImage:
                    "wind",
                iconColor: .cyan
            )

            MetricCard(
                title: "Vehicles",
                value:
                    "\(vehicleCount.total)",
                systemImage:
                    "car.fill",
                iconColor: .green
            )
        }
        .padding(.top, 24)
    }
}

// MARK: - Weather

private extension PointDetailView {

    var temperatureText: String {

        String(
            format: "%.1f°C",
            weather.current.temperature2m
        )
    }

    var humidityText: String {

        String(
            format: "%.0f%%",
            weather.current.relativeHumidity2m
        )
    }

    var windText: String {

        String(
            format: "%.1f m/s",
            weather.current.windSpeed10m
        )
    }
}

// MARK: - Vehicle Breakdown

private extension PointDetailView {

    var vehicleBreakdownSection: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text(
                "Vehicle Breakdown"
            )
            .font(.headline)
            .fontWeight(.bold)

            Text(
                "Jumlah kendaraan terdeteksi selama \(traffic.intervalMenit) menit"
            )
            .font(.caption)
            .foregroundStyle(
                .secondary
            )

            VehicleBreakdownView(
                vehicle: traffic
            )
        }
    }
}

// MARK: - Footer

private extension PointDetailView {

    var footerNote: some View {

        Text(
            """
            PM2.5 dihitung untuk setiap interval CCTV secara terpisah berdasarkan jumlah kendaraan pada interval tersebut, emission factor, ruas jalan \(Int(trafficPoint.roadLengthMeters)) meter, durasi observasi CCTV, dan kondisi angin pada saat data diperoleh.

            Setiap interval baru menggunakan data kendaraan baru dan tidak menambahkan PM2.5 dari interval sebelumnya.
            """
        )
        .font(.caption2)
        .foregroundStyle(
            .secondary
        )
        .multilineTextAlignment(
            .center
        )
        .frame(
            maxWidth: .infinity
        )
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
                    .font(
                        .system(
                            size: 18
                        )
                    )
                    .foregroundStyle(
                        .secondary
                    )

                Spacer()

                Image(
                    systemName:
                        systemImage
                )
                .font(
                    .system(
                        size: 24,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    iconColor
                )
            }

            Text(value)
                .font(
                    .system(
                        size: 30,
                        weight: .bold
                    )
                )
                .minimumScaleFactor(
                    0.8
                )
                .lineLimit(1)
        }
        .padding(20)
        .frame(
            maxWidth: .infinity
        )
        .frame(
            minHeight: 150
        )
        .background(
            Color(
                .secondarySystemGroupedBackground
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
        .accessibilityElement(
            children: .combine
        )
    }
}
