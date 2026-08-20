//
//  AirQualityService.swift
//  Pirless
//
//  Created by Graceila Natasya on 19/08/26.
//


import Foundation

final class AirQualityService {

    static let shared = AirQualityService()

    private let apiClient: APIClient

    // MARK: - Constants

    /// Interval data traffic dari CCTV.
    static let trafficUpdateIntervalMinutes: Int = 7

    // MARK: - Initialization

    init(
        apiClient: APIClient = .shared
    ) {
        self.apiClient = apiClient
    }

    // MARK: - Emission Factors

    /*
     Faktor emisi PM2.5.
     
     Nilai ini diperlakukan sebagai:
     mg PM2.5 per kendaraan selama interval pengamatan.
     
     Faktor sengaja dibuat lebih kecil daripada versi sebelumnya
     karena versi sebelumnya menghasilkan nilai ribuan mg hanya
     dari satu interval 7 menit.
     */

    private let efCar: Double = 1.26
    private let efMotorcycle: Double = 5.0
    private let efBus: Double = 9.1
    private let efTruck: Double = 11.8

    // MARK: - Wind

    private let minimumWindSpeed: Double = 0.5

    // MARK: - Fetch Weather

    func fetchWeather(
        for trafficPoint: TrafficPoint
    ) async throws -> WeatherResponse {

        try await apiClient.fetchWeather(
            latitude: trafficPoint.latitude,
            longitude: trafficPoint.longitude
        )
    }

    // MARK: - Raw PM2.5

    func calculateRawPM25(
        vehicleCount: VehicleCount
    ) -> Double {

        let carEmission =
            Double(vehicleCount.car) * efCar

        let motorcycleEmission =
            Double(vehicleCount.motorcycle) * efMotorcycle

        let busEmission =
            Double(vehicleCount.bus) * efBus

        let truckEmission =
            Double(vehicleCount.truck) * efTruck

        let totalEmission =
            carEmission
            + motorcycleEmission
            + busEmission
            + truckEmission

        return max(totalEmission, 0)
    }

    // MARK: - Wind Adjustment

    func applyWindAdjustment(
        emission: Double,
        windSpeed: Double
    ) -> Double {

        let safeWindSpeed =
            max(
                windSpeed,
                minimumWindSpeed
            )

        /*
         * Angin lebih tinggi -> dispersi lebih besar
         * -> estimasi dampak konsentrasi lebih rendah.
         */

        let adjustedEmission =
            emission / safeWindSpeed

        return max(adjustedEmission, 0)
    }

    // MARK: - PM2.5 Per Interval

    func calculatePM25ForInterval(
        vehicleCount: VehicleCount,
        intervalMinutes: Int,
        windSpeed: Double
    ) -> Double {

        guard intervalMinutes > 0 else {
            return 0
        }

        let rawEmission =
            calculateRawPM25(
                vehicleCount: vehicleCount
            )

        let adjustedEmission =
            applyWindAdjustment(
                emission: rawEmission,
                windSpeed: windSpeed
            )

        /*
         * vehicleCount sudah merupakan jumlah kendaraan
         * yang terdeteksi SELAMA interval tersebut.
         *
         * Jadi tidak boleh dikalikan 60 / intervalMinutes.
         *
         * Misalnya:
         * 746 kendaraan dalam 7 menit
         * tetap dihitung sebagai 746 kendaraan untuk interval itu.
         */

        return max(adjustedEmission, 0)
    }

    // MARK: - PM2.5 From Traffic + Weather

    func calculatePM25(
        traffic: VehicleTrafficResponse,
        weather: WeatherResponse
    ) -> Double {

        let vehicleCount =
            traffic.volumeKendaraan.asVehicleCount

        let windSpeed =
            weather.current.windSpeed10m

        /*
         * PENTING:
         * gunakan interval asli dari API,
         * bukan angka hard-coded 7.
         */

        return calculatePM25ForInterval(
            vehicleCount: vehicleCount,
            intervalMinutes: traffic.intervalMenit,
            windSpeed: windSpeed
        )
    }

    // MARK: - Direct PM2.5

    func calculatePM25(
        vehicleCount: VehicleCount,
        intervalMinutes: Int =
            AirQualityService.trafficUpdateIntervalMinutes,
        windSpeed: Double
    ) -> Double {

        return calculatePM25ForInterval(
            vehicleCount: vehicleCount,
            intervalMinutes: intervalMinutes,
            windSpeed: windSpeed
        )
    }

    // MARK: - Raw PM2.5 From Traffic

    func calculateRawPM25(
        traffic: VehicleTrafficResponse
    ) -> Double {

        let vehicleCount =
            traffic.volumeKendaraan.asVehicleCount

        return calculateRawPM25(
            vehicleCount: vehicleCount
        )
    }

    // MARK: - Gram Conversion

    func calculatePM25Gram(
        traffic: VehicleTrafficResponse,
        weather: WeatherResponse
    ) -> Double {

        let pm25Mg =
            calculatePM25(
                traffic: traffic,
                weather: weather
            )

        return pm25Mg / 1000.0
    }

    // MARK: - Create Reading

    func createReading(
        trafficPoint: TrafficPoint,
        vehicleCount: VehicleCount,
        intervalMinutes: Int =
            AirQualityService.trafficUpdateIntervalMinutes,
        timestamp: Date = Date()
    ) async throws -> AirQualityReading {

        let weather =
            try await fetchWeather(
                for: trafficPoint
            )

        let windSpeed =
            weather.current.windSpeed10m

        let pm25 =
            calculatePM25ForInterval(
                vehicleCount: vehicleCount,
                intervalMinutes: intervalMinutes,
                windSpeed: windSpeed
            )

        return AirQualityReading(
            id: UUID(),
            trafficPointId:
                trafficPoint.id,
            timestamp:
                timestamp,
            pm25:
                pm25,
            pm25IntervalMinutes:
                intervalMinutes,
            windSpeed:
                windSpeed,
            humidity:
                weather.current.relativeHumidity2m,
            vehicleCount:
                vehicleCount
        )
    }

    // MARK: - Create & Save

    func processAndSendReading(
        trafficPoint: TrafficPoint,
        vehicleCount: VehicleCount,
        intervalMinutes: Int =
            AirQualityService.trafficUpdateIntervalMinutes
    ) async throws -> AirQualityReading {

        let reading =
            try await createReading(
                trafficPoint: trafficPoint,
                vehicleCount: vehicleCount,
                intervalMinutes: intervalMinutes
            )

        await HistoryStore.shared.add(
            reading
        )

        return reading
    }
}
