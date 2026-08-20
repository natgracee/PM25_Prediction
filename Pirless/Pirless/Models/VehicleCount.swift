//
//  VehicleCount.swift
//  Pirless
//

import Foundation

struct VehicleCount: Codable, Equatable {

    var car: Int
    var motorcycle: Int
    var bus: Int
    var truck: Int

    init(
        car: Int = 0,
        motorcycle: Int = 0,
        bus: Int = 0,
        truck: Int = 0
    ) {
        self.car = max(car, 0)
        self.motorcycle = max(motorcycle, 0)
        self.bus = max(bus, 0)
        self.truck = max(truck, 0)
    }

    var total: Int {

        car
        + motorcycle
        + bus
        + truck
    }
}
