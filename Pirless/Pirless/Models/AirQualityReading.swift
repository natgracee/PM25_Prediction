//
//  AirQualityReading.swift
//  Pirless
//

import Foundation

struct AirQualityReading: Identifiable, Codable {
    
    // MARK: - Identity
    
    let id: UUID
    
    // MARK: - Traffic Point
    
    let trafficPointId: UUID
    
    // MARK: - Timestamp
    
    let timestamp: Date
    
    // MARK: - PM2.5
    
    let pm25: Double
    
    /// Interval pengambilan data traffic.
    let pm25IntervalMinutes: Int
    
    // MARK: - Weather
    
    /// Kecepatan angin dalam m/s.
    let windSpeed: Double
    
    /// Kelembapan relatif dalam persen.
    let humidity: Double
    
    // MARK: - Vehicle
    
    /// Jumlah kendaraan yang terdeteksi CCTV
    /// selama interval pengamatan.
    let vehicleCount: VehicleCount
    
    // MARK: - Initializer
    
    init(
        id: UUID = UUID(),
        trafficPointId: UUID,
        timestamp: Date,
        pm25: Double,
        pm25IntervalMinutes: Int = 7,
        windSpeed: Double,
        humidity: Double,
        vehicleCount: VehicleCount
    ) {
        self.id = id
        self.trafficPointId = trafficPointId
        self.timestamp = timestamp
        self.pm25 = pm25
        self.pm25IntervalMinutes =
            pm25IntervalMinutes
        self.windSpeed = windSpeed
        self.humidity = humidity
        self.vehicleCount = vehicleCount
    }
}
