//
//  HistoryStore.swift
//  Pirless
//
//  Penyimpanan lokal data riwayat PM2.5.
//

import Foundation
import Combine

@MainActor
final class HistoryStore: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = HistoryStore()
    
    // MARK: - Data
    
    @Published private(set) var readings:
        [AirQualityReading] = []
    
    // MARK: - Storage
    
    private let storageKey =
        "air_quality_readings"
    
    // MARK: - Init
    
    private init() {
        load()
    }
    
    // MARK: - Add Reading
    
    func add(
        _ reading: AirQualityReading
    ) {
        
        // Jangan simpan ID yang sama dua kali.
        guard !readings.contains(
            where: {
                $0.id == reading.id
            }
        ) else {
            return
        }
        
        readings.append(reading)
        
        readings.sort {
            $0.timestamp < $1.timestamp
        }
        
        save()
    }
    
    // MARK: - Add Multiple Readings
    
    func add(
        contentsOf newReadings:
            [AirQualityReading]
    ) {
        
        let existingIDs =
            Set(
                readings.map(\.id)
            )
        
        let uniqueReadings =
            newReadings.filter {
                !existingIDs.contains(
                    $0.id
                )
            }
        
        guard !uniqueReadings.isEmpty else {
            return
        }
        
        readings.append(
            contentsOf:
                uniqueReadings
        )
        
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
            $0.trafficPointId ==
                trafficPointId
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
            
            let data =
                try JSONEncoder()
                    .encode(readings)
            
            UserDefaults.standard.set(
                data,
                forKey: storageKey
            )
            
        } catch {
            
            print(
                "HistoryStore save error:",
                error.localizedDescription
            )
        }
    }
    
    // MARK: - Load
    
    private func load() {
        
        guard let data =
            UserDefaults.standard.data(
                forKey: storageKey
            )
        else {
            readings = []
            return
        }
        
        do {
            
            readings =
                try JSONDecoder()
                    .decode(
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
