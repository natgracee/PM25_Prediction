//
//  AirQualityLevel.swift
//  Pirless
//
//  Created by Graceila Natasya on 17/08/26.
//


//
//  AirQualityLevel.swift
//  Pirless
//
//  Kategori kualitas udara.
//

import Foundation

enum AirQualityLevel: String, Codable, CaseIterable {

    case good = "Good"
    case moderate = "Moderate"
    case unhealthy = "Unhealthy"

    static func from(
        pm25: Double
    ) -> AirQualityLevel {

        // ==================================================
        // SEMENTARA
        //
        // Batas kategori akan kita revisi ketika
        // metodologi PM2.5 sudah ditentukan.
        // ==================================================

        if pm25 <= 15 {
            return .good
        }

        if pm25 <= 35 {
            return .moderate
        }

        return .unhealthy
    }
}
