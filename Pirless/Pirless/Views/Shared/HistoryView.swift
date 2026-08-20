//
//  HistoryFilter.swift
//  Pirless
//
//  Created by Graceila Natasya on 19/08/26.
//


//
//  HistoryView.swift
//  Pirless
//
//  History PM2.5 berdasarkan TrafficPoint.
//

import SwiftUI
import Charts
import UIKit

// MARK: - History Filter

enum HistoryFilter: String, CaseIterable, Identifiable {

    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"

    var id: String {
        rawValue
    }
}

// MARK: - Maintenance State

private extension HistoryView {

    var maintenanceState: some View {

        VStack(spacing: 8) {

            Text("We'll still warming up this page")
                .font(
                    .system(
                        size: 17,
                        weight: .bold
                    )
                )
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            Text("Check back soon")
                .font(
                    .system(
                        size: 14,
                        weight: .regular
                    )
                )
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 550,
            alignment: .center
        )
    }
}

// MARK: - Chart Data

struct HistoryChartData: Identifiable {

    let id: UUID
    let date: Date
    let pm25: Double
    let vehicles: Int

    init(
        id: UUID = UUID(),
        date: Date,
        pm25: Double,
        vehicles: Int
    ) {
        self.id = id
        self.date = date
        self.pm25 = pm25
        self.vehicles = vehicles
    }
}

// MARK: - History View

struct HistoryView: View {

    // MARK: - Input

    let trafficPoint: TrafficPoint

    // MARK: - Environment

    @StateObject
    private var historyStore = HistoryStore.shared

    @Environment(\.dismiss)
    private var dismiss

    // MARK: - State

    @State
    private var selectedFilter: HistoryFilter = .daily

    @State
    private var chartData: [HistoryChartData] = []

    @State
    private var csvURL: URL?

    @State
    private var showShareSheet = false

    // MARK: - Body

    var body: some View {

        ScrollView {

            VStack(spacing: 20) {

                headerView

                filterSegmentedControl

                if selectedFilter == .daily {

                    chartCard
                    saveButton
                    metricsView

                } else {

                    maintenanceState
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 30)
        }
        .background(
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden()
        .onAppear {
            reloadData()
        }
        .onChange(of: selectedFilter) { _, _ in
            reloadData()
        }
        .sheet(isPresented: $showShareSheet) {

            if let csvURL {

                ShareSheet(items: [csvURL])
                    .presentationDetents([.medium])
            }
        }
    }
}

// MARK: - Header

private extension HistoryView {

    var headerView: some View {

        HStack {

            Button {

                dismiss()

            } label: {

                Image(systemName: "chevron.left")
                    .font(
                        .system(
                            size: 18,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(.primary)
                    .frame(
                        width: 40,
                        height: 40
                    )
            }
            .accessibilityLabel("Kembali")

            Spacer()

            VStack(spacing: 3) {

                Text("History")
                    .font(
                        .system(
                            size: 20,
                            weight: .bold
                        )
                    )

                Text(trafficPoint.locationName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer()

            Color.clear
                .frame(
                    width: 40,
                    height: 40
                )
        }
    }
}

// MARK: - Filter

private extension HistoryView {

    var filterSegmentedControl: some View {

        HStack(spacing: 4) {

            filterButton(
                title: "Daily",
                filter: .daily
            )

            filterButton(
                title: "Weekly",
                filter: .weekly
            )

            filterButton(
                title: "Monthly",
                filter: .monthly
            )
        }
        .padding(4)
        .background(
            Color(.systemGray4)
        )
        .clipShape(
            Capsule()
        )
    }

    @ViewBuilder
    func filterButton(
        title: String,
        filter: HistoryFilter
    ) -> some View {

        let selected = selectedFilter == filter

        Button {

            withAnimation(
                .easeInOut(duration: 0.2)
            ) {
                selectedFilter = filter
            }

        } label: {

            Text(title)
                .font(
                    .system(
                        size: 15,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    selected
                        ? Color.black
                        : Color.white
                )
                .frame(
                    maxWidth: .infinity
                )
                .padding(.vertical, 10)
                .background {

                    if selected {

                        Capsule()
                            .fill(
                                Color(
                                    red: 0.68,
                                    green: 0.85,
                                    blue: 0.95
                                )
                            )
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Chart Card

private extension HistoryView {

    var chartCard: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {

                    Text("PM2.5")
                        .font(
                            .system(
                                size: 18,
                                weight: .bold
                            )
                        )

                    Text(trafficPoint.locationName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text("\(chartData.count) data")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if chartData.isEmpty {

                emptyChart

            } else {

                pm25Chart
            }
        }
        .padding(16)
        .background(
            Color(
                red: 0.90,
                green: 0.94,
                blue: 0.93
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
        )
    }
}

// MARK: - Empty Daily Chart

private extension HistoryView {

    var emptyChart: some View {

        VStack(spacing: 10) {

            ZStack {

                Circle()
                    .fill(
                        Color.secondary.opacity(0.10)
                    )
                    .frame(
                        width: 64,
                        height: 64
                    )

                Image(
                    systemName: "chart.xyaxis.line"
                )
                .font(
                    .system(
                        size: 28,
                        weight: .medium
                    )
                )
                .foregroundStyle(.secondary)
            }

            Text("Belum ada riwayat")
                .font(
                    .system(
                        size: 15,
                        weight: .semibold
                    )
                )

            Text(
                "Belum ada data PM2.5 untuk titik ini."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 230
        )
    }
}

// MARK: - Under Maintenance

private extension HistoryView {

    var maintenanceView: some View {

        VStack(spacing: 16) {

            ZStack {

                Circle()
                    .fill(
                        Color.orange.opacity(0.13)
                    )
                    .frame(
                        width: 76,
                        height: 76
                    )

                Image(
                    systemName:
                        "wrench.and.screwdriver.fill"
                )
                .font(
                    .system(
                        size: 29,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.orange)
            }

            VStack(spacing: 7) {

                Text("Under Maintenance")
                    .font(
                        .system(
                            size: 18,
                            weight: .bold
                        )
                    )

                Text(
                    maintenanceMessage
                )
                .font(
                    .system(
                        size: 14,
                        weight: .regular
                    )
                )
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

                Text("Please check back later.")
                    .font(
                        .system(
                            size: 13,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(.secondary)
            }
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 230
        )
        .padding(.horizontal, 20)
    }

    var maintenanceMessage: String {

        switch selectedFilter {

        case .weekly:
            return """
            Weekly history is currently
            under maintenance.
            """

        case .monthly:
            return """
            Monthly history is currently
            under maintenance.
            """

        case .daily:
            return ""
        }
    }
}

// MARK: - PM2.5 Chart

private extension HistoryView {

    var pm25Chart: some View {

        Chart {

            ForEach(chartData) { item in

                AreaMark(
                    x: .value(
                        "Waktu",
                        item.date
                    ),
                    y: .value(
                        "PM2.5",
                        item.pm25
                    )
                )
                .foregroundStyle(
                    Color(
                        red: 0.29,
                        green: 0.75,
                        blue: 0.68
                    )
                    .opacity(0.25)
                )

                LineMark(
                    x: .value(
                        "Waktu",
                        item.date
                    ),
                    y: .value(
                        "PM2.5",
                        item.pm25
                    )
                )
                .foregroundStyle(
                    Color(
                        red: 0.10,
                        green: 0.55,
                        blue: 0.48
                    )
                )
                .lineStyle(
                    StrokeStyle(
                        lineWidth: 2.5
                    )
                )

                PointMark(
                    x: .value(
                        "Waktu",
                        item.date
                    ),
                    y: .value(
                        "PM2.5",
                        item.pm25
                    )
                )
                .foregroundStyle(
                    Color(
                        red: 0.10,
                        green: 0.55,
                        blue: 0.48
                    )
                )
            }
        }
        .frame(height: 230)
        .chartXAxis {
            AxisMarks()
        }
        .chartYAxis {
            AxisMarks(
                position: .leading
            )
        }
    }
}

// MARK: - Save Button

private extension HistoryView {

    var saveButton: some View {

        HStack {

            Spacer()

            Button {

                createCSV()

            } label: {

                HStack(spacing: 7) {

                    Image(
                        systemName:
                            "square.and.arrow.down"
                    )

                    Text("Save Data")
                        .font(
                            .system(
                                size: 15,
                                weight: .semibold
                            )
                        )
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Color(
                        red: 0.10,
                        green: 0.55,
                        blue: 0.48
                    )
                )
                .clipShape(
                    Capsule()
                )
            }
            .buttonStyle(.plain)
            .disabled(chartData.isEmpty)
            .opacity(
                chartData.isEmpty
                    ? 0.5
                    : 1
            )
        }
    }
}

// MARK: - Metrics

private extension HistoryView {

    var metricsView: some View {

        VStack(spacing: 14) {

            metricCard(
                title: "AVG PM2.5",
                value: formatPM25(
                    averagePM25
                ),
                unit: "PM2.5",
                icon: "wind",
                iconColor: .green
            )

            metricCard(
                title: "PEAK PM2.5",
                value: formatPM25(
                    peakPM25
                ),
                unit: "PM2.5",
                icon:
                    "exclamationmark.triangle.fill",
                iconColor: .red
            )

            metricCard(
                title: "AVG VEHICLES",
                value: formatVehicles(
                    averageVehicles
                ),
                unit: "vehicles / interval",
                icon: "car.fill",
                iconColor: .blue
            )
        }
    }

    func metricCard(
        title: String,
        value: String,
        unit: String,
        icon: String,
        iconColor: Color
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            HStack(spacing: 7) {

                Image(
                    systemName: icon
                )
                .foregroundStyle(
                    iconColor
                )

                Text(title)
                    .font(
                        .system(
                            size: 13,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        iconColor
                    )
            }

            HStack(
                alignment: .firstTextBaseline,
                spacing: 4
            ) {

                Text(value)
                    .font(
                        .system(
                            size: 32,
                            weight: .bold
                        )
                    )

                Text(unit)
                    .font(
                        .system(
                            size: 15
                        )
                    )
                    .foregroundStyle(
                        .secondary
                    )
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(18)
        .background(
            Color(.systemBackground)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
        )
    }
}

// MARK: - Calculations

private extension HistoryView {

    var pointReadings: [AirQualityReading] {

        historyStore.readings(
            for: trafficPoint.id
        )
    }

    var averagePM25: Double {

        guard !chartData.isEmpty else {
            return 0
        }

        let total =
            chartData.reduce(0.0) {
                partialResult,
                item in
                partialResult + item.pm25
            }

        return total / Double(
            chartData.count
        )
    }

    var peakPM25: Double {

        chartData
            .map(\.pm25)
            .max() ?? 0
    }

    var averageVehicles: Double {

        guard !chartData.isEmpty else {
            return 0
        }

        let total =
            chartData.reduce(0) {
                partialResult,
                item in
                partialResult + item.vehicles
            }

        return Double(total)
            / Double(chartData.count)
    }
}

// MARK: - Load Data

private extension HistoryView {

    func reloadData() {

        guard selectedFilter == .daily else {

            chartData = []
            return
        }

        let readings = pointReadings

        guard !readings.isEmpty else {

            chartData = []
            return
        }

        let calendar = Calendar.current
        let now = Date()

        let filteredReadings =
            readings.filter { reading in

                calendar.isDate(
                    reading.timestamp,
                    inSameDayAs: now
                )
            }

        chartData =
            filteredReadings
                .sorted {
                    $0.timestamp < $1.timestamp
                }
                .map { reading in

                    HistoryChartData(
                        id: reading.id,
                        date: reading.timestamp,
                        pm25: reading.pm25,
                        vehicles:
                            reading.vehicleCount.total
                    )
                }
    }
}

// MARK: - CSV

private extension HistoryView {

    func createCSV() {

        guard selectedFilter == .daily else {
            return
        }

        guard !chartData.isEmpty else {
            return
        }

        let formatter =
            ISO8601DateFormatter()

        let location =
            trafficPoint.locationName
                .replacingOccurrences(
                    of: ",",
                    with: " "
                )

        var csv =
            "Lokasi,Waktu,PM2.5 (ug/m3),Kendaraan (per interval),Interval (menit),Wind Speed (m/s),Humidity (%)\n"

        csv += "\n"

        let selectedIDs =
            Set(chartData.map(\.id))

        let readings =
            pointReadings
                .filter {
                    selectedIDs.contains(
                        $0.id
                    )
                }
                .sorted {
                    $0.timestamp < $1.timestamp
                }

        for reading in readings {

            let date =
                formatter.string(
                    from: reading.timestamp
                )

            let row =
                "\(location)," +
                "\(date)," +
                "\(reading.pm25)," +
                "\(reading.vehicleCount.total)," +
                "\(reading.pm25IntervalMinutes)," +
                "\(reading.windSpeed)," +
                "\(reading.humidity)\n"

            csv += row
        }

        let fileName =
            "Pirless_\(safeFileName(location))_History.csv"

        let url =
            FileManager.default
                .temporaryDirectory
                .appendingPathComponent(
                    fileName
                )

        do {

            try csv.write(
                to: url,
                atomically: true,
                encoding: .utf8
            )

            csvURL = url
            showShareSheet = true

        } catch {

            print(
                "❌ CSV ERROR:",
                error.localizedDescription
            )
        }
    }

    func safeFileName(
        _ value: String
    ) -> String {

        let invalidCharacters =
            CharacterSet(
                charactersIn:
                    "/\\?%*|\"<>:"
            )

        return value
            .components(
                separatedBy:
                    invalidCharacters
            )
            .joined(
                separator: "_"
            )
            .replacingOccurrences(
                of: " ",
                with: "_"
            )
    }
}

// MARK: - Formatting

private extension HistoryView {

    func formatPM25(
        _ value: Double
    ) -> String {

        value.formatted(
            .number
                .precision(
                    .fractionLength(1)
                )
        )
    }

    func formatVehicles(
        _ value: Double
    ) -> String {

        value.formatted(
            .number
                .precision(
                    .fractionLength(0)
                )
        )
    }
}

// MARK: - Share Sheet

struct ShareSheet:
    UIViewControllerRepresentable {

    let items: [Any]

    func makeUIViewController(
        context: Context
    ) -> UIActivityViewController {

        UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController:
            UIActivityViewController,
        context: Context
    ) {
        // Tidak ada update yang diperlukan.
    }
}

// MARK: - Preview

#Preview {

    NavigationStack {

        HistoryView(
            trafficPoint:
                TrafficPoint(
                    id: UUID(),
                    locationName:
                        "Baranangsiang",
                    latitude: -6.6015,
                    longitude: 106.8061
                )
        )
    }
}
