//
//  TrafficPoint.swift
//  Pirless
//
//  Created by Muh. Naufal Fahri Salim on 8/13/26.
//

import Foundation

struct TrafficPoint: Identifiable {
    let id = UUID()
    var locationName: String  // lokasi cctv

    var carCount: Int = 0
    var motorcycleCount: Int = 0
    var busCount: Int = 0
    var truckCount: Int = 0

    var windSpeed: Double = 2.5  // U: kecepatan angin (default BMKG)
    var mixingHeight: Double = 800.0  // H: mixing height default
    var streetWidth: Double = 14.0  // W: lebar jalan default

    // satuan mg/km
    private let efCar: Double = 1.26
    private let efMotorcycle: Double = 5.0
    private let efBus: Double = 91.0
    private let efTruck: Double = 118.0

    var totalEmissionQ: Double {
        let qCar = Double(carCount) * efCar
        let qMotor = Double(motorcycleCount) * efMotorcycle
        let qBus = Double(busCount) * efBus
        let qTruck = Double(truckCount) * efTruck

        return qCar + qMotor + qBus + qTruck
    }

    var predictedPM25C: Double {
        let safeWindSpeed = max(windSpeed, 0.1)

        // rumus: C = Q / (U * H * W)
        return totalEmissionQ / (safeWindSpeed * mixingHeight * streetWidth)
    }
}
