//
//  VehicleTrafficResponse.swift
//  Pirless
//

import Foundation

struct VehicleTrafficResponse: Codable, Identifiable {

    // MARK: - Identity

    var id: String {
        "\(kamera)-\(mulai)"
    }

    // MARK: - Camera

    let kamera: String
    let lokasi: String

    // MARK: - Interval

    /// Durasi pengamatan CCTV dalam menit.
    let intervalMenit: Int

    let mulai: String
    let selesai: String

    // MARK: - Vehicle

    /// Jumlah masing-masing kendaraan
    /// yang terdeteksi selama interval CCTV.
    let volumeKendaraan: VehicleVolume

    /// Total kendaraan yang terdeteksi
    /// selama interval CCTV.
    let total: Int

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case kamera
        case lokasi
        case intervalMenit = "interval_menit"
        case mulai
        case selesai
        case volumeKendaraan = "volume_kendaraan"
        case total
    }

    // MARK: - Vehicle Count

    /// Vehicle count selama interval CCTV.
    var vehicleCount: VehicleCount {
        volumeKendaraan.asVehicleCount
    }
}

// MARK: - Vehicle Volume

struct VehicleVolume: Codable {

    let motor: Int
    let mobil: Int
    let bus: Int
    let truk: Int

    var asVehicleCount: VehicleCount {
        VehicleCount(
            car: mobil,
            motorcycle: motor,
            bus: bus,
            truck: truk
        )
    }

    /// Total kendaraan selama interval CCTV.
    var total: Int {
        motor
        + mobil
        + bus
        + truk
    }
}


