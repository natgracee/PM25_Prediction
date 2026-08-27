//
//  AirQualityLevel.swift
//  Pirless
//

import Foundation

enum AirQualityLevel: String, Codable, CaseIterable {

    case good = "Good"
    case moderate = "Moderate"
    case unhealthy = "Unhealthy"

    static func from(pm25: Double) -> AirQualityLevel {
        if pm25 <= 15 { return .good }
        if pm25 <= 35 { return .moderate }
        return .unhealthy
    }
}
