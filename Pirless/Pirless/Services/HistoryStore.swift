//
//  HistoryStore.swift
//  Pirless
//
//  Created by Graceila Natasya on 19/08/26.
//

//  Penyimpanan lokal data riwayat PM2.5.
//

import Foundation
import Combine

@MainActor
final class HistoryStore: ObservableObject {

    static let shared = HistoryStore()

    @Published private(set) var readings: [AirQualityReading] = []

    private let storageKey = "air_quality_readings"

    private init() {
        load()
    }

    // MARK: - Add Reading

    func add(_ reading: AirQualityReading) {
        readings.append(reading)

        // Urutkan dari data paling lama ke paling baru.
        readings.sort {
            $0.timestamp < $1.timestamp
        }

        save()
    }

    // MARK: - Add Multiple Readings

    func add(contentsOf newReadings: [AirQualityReading]) {
        readings.append(contentsOf: newReadings)

        readings.sort {
            $0.timestamp < $1.timestamp
        }

        save()
    }

    // MARK: - Get Readings

    func readings(
        for trafficPointId: UUID
    ) -> [AirQualityReading] {
        readings.filter {
            $0.trafficPointId == trafficPointId
        }
    }

    // MARK: - Delete All

    func removeAll() {
        readings.removeAll()
        save()
    }

    // MARK: - Save

    private func save() {
        do {
            let data = try JSONEncoder().encode(readings)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print(
                "HistoryStore save error:",
                error.localizedDescription
            )
        }
    }

    // MARK: - Load

    private func load() {
        guard let data = UserDefaults.standard.data(
            forKey: storageKey
        ) else {
            readings = []
            return
        }

        do {
            readings = try JSONDecoder().decode(
                [AirQualityReading].self,
                from: data
            )

            readings.sort {
                $0.timestamp < $1.timestamp
            }
        } catch {
            print(
                "HistoryStore load error:",
                error.localizedDescription
            )

            readings = []
        }
    }
}
