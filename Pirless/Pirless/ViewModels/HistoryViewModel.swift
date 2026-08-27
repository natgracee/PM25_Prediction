//
//  HistoryViewModel.swift
//  Pirless
//

import Foundation

@Observable
@MainActor
final class HistoryViewModel {

    // MARK: - Input

    let trafficPoint: TrafficPoint

    // MARK: - State

    var selectedFilter: HistoryFilter = .daily
    var csvURL: URL? = nil
    var showShareSheet = false

    // MARK: - Init

    init(trafficPoint: TrafficPoint) {
        self.trafficPoint = trafficPoint
    }

    // MARK: - Chart Data
    //
    // Computed property — bereaksi otomatis terhadap perubahan
    // HistoryStore.shared.readings karena keduanya @Observable.

    var chartData: [HistoryChartData] {
        guard selectedFilter == .daily else { return [] }

        let readings = HistoryStore.shared.readings(for: trafficPoint.id)
        guard !readings.isEmpty else { return [] }

        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(
            byAdding: .day, value: 1, to: startOfToday
        ) ?? now

        return readings
            .filter { $0.timestamp >= startOfToday && $0.timestamp < endOfToday }
            .sorted { $0.timestamp < $1.timestamp }
            .map {
                HistoryChartData(
                    id: $0.id,
                    date: $0.timestamp,
                    pm25: $0.pm25,
                    vehicles: $0.vehicleCount.total
                )
            }
    }

    // MARK: - Metrics

    var averagePM25: Double {
        guard !chartData.isEmpty else { return 0 }
        return chartData.reduce(0.0) { $0 + $1.pm25 } / Double(chartData.count)
    }

    var peakPM25: Double {
        chartData.map(\.pm25).max() ?? 0
    }

    var averageVehicles: Double {
        guard !chartData.isEmpty else { return 0 }
        return Double(chartData.reduce(0) { $0 + $1.vehicles }) / Double(chartData.count)
    }

    // MARK: - CSV

    func createCSV() {
        guard selectedFilter == .daily, !chartData.isEmpty else { return }

        let formatter = ISO8601DateFormatter()
        let location = trafficPoint.locationName
            .replacingOccurrences(of: ",", with: " ")

        var csv = "Lokasi,Waktu,PM2.5 (ug/m3),Kendaraan (per interval),Interval (menit),Wind Speed (m/s),Humidity (%)\n"

        let selectedIDs = Set(chartData.map(\.id))
        let readings = HistoryStore.shared.readings(for: trafficPoint.id)
            .filter { selectedIDs.contains($0.id) }
            .sorted { $0.timestamp < $1.timestamp }

        for reading in readings {
            let date = formatter.string(from: reading.timestamp)
            csv += "\(location),\(date),\(reading.pm25),\(reading.vehicleCount.total),\(reading.pm25IntervalMinutes),\(reading.windSpeed),\(reading.humidity)\n"
        }

        let fileName = "Pirless_\(safeFileName(location))_History.csv"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)

        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            csvURL = url
            showShareSheet = true
        } catch {
            print("CSV ERROR:", error.localizedDescription)
        }
    }

    private func safeFileName(_ value: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return value
            .components(separatedBy: invalidCharacters)
            .joined(separator: "_")
            .replacingOccurrences(of: " ", with: "_")
    }

    // MARK: - Formatting

    func formatPM25(_ value: Double) -> String {
        guard !chartData.isEmpty else { return "—" }
        return value.formatted(.number.precision(.fractionLength(1)))
    }

    func formatVehicles(_ value: Double) -> String {
        guard !chartData.isEmpty else { return "—" }
        return value.formatted(.number.precision(.fractionLength(0)))
    }
}
