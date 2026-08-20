//
//  TrafficPoint.swift
//  Pirless
//

import Foundation
import MapKit

struct TrafficPoint: Identifiable, Codable, Equatable, Hashable {

    // MARK: - Identity

    let id: UUID

    // MARK: - Location

    let locationName: String
    let latitude: Double
    let longitude: Double

    // MARK: - Vehicle Count
    //
    // Jumlah kendaraan berasal dari SATU interval CCTV.
    // Default interval = 7 menit.
    //
    // PENTING:
    // Nilai ini bukan kendaraan per jam.
    // Nilai ini bukan total kumulatif.
    // Nilai ini adalah jumlah kendaraan pada
    // interval pengamatan saat ini.

    var carCount: Int = 0
    var motorcycleCount: Int = 0
    var busCount: Int = 0
    var truckCount: Int = 0

    // MARK: - Environment

    /// Kecepatan angin dalam m/s.
    var windSpeed: Double = 2.5

    /// Mixing height dalam meter.
    var mixingHeight: Double = 800.0

    /// Lebar jalan dalam meter.
    var streetWidth: Double = 14.0

    // MARK: - Effective Distance

    /// Panjang segmen jalan yang digunakan
    /// sebagai effective distance model.
    ///
    /// Default:
    /// 100 meter = 0.1 km.

    var roadLengthMeters: Double = 100.0

    // MARK: - PM2.5 Calibration

    /// Konsentrasi PM2.5 latar belakang.
    ///
    /// Satuan: µg/m³.

    var backgroundPM25: Double = 10.0

    /// Faktor kalibrasi empiris.
    ///
    /// BUKAN emission factor kendaraan.

    var pm25CalibrationFactor: Double = 50.0

    // MARK: - Emission Factors

    //
    // Satuan:
    // mg/km per kendaraan
    //
    // Tidak dikonversi menjadi kendaraan/jam.

    private static let efCar: Double = 1.26
    private static let efMotorcycle: Double = 5.0
    private static let efBus: Double = 91.0
    private static let efTruck: Double = 118.0

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        locationName: String,
        latitude: Double,
        longitude: Double,
        carCount: Int = 0,
        motorcycleCount: Int = 0,
        busCount: Int = 0,
        truckCount: Int = 0,
        windSpeed: Double = 2.5,
        mixingHeight: Double = 800.0,
        streetWidth: Double = 14.0,
        roadLengthMeters: Double = 100.0,
        backgroundPM25: Double = 10.0,
        pm25CalibrationFactor: Double = 50.0
    ) {
        self.id = id
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude

        self.carCount = max(carCount, 0)
        self.motorcycleCount = max(motorcycleCount, 0)
        self.busCount = max(busCount, 0)
        self.truckCount = max(truckCount, 0)

        self.windSpeed = max(windSpeed, 0.1)
        self.mixingHeight = max(mixingHeight, 1.0)
        self.streetWidth = max(streetWidth, 1.0)

        self.roadLengthMeters = max(
            roadLengthMeters,
            1.0
        )

        self.backgroundPM25 = max(
            backgroundPM25,
            0.0
        )

        self.pm25CalibrationFactor = max(
            pm25CalibrationFactor,
            0.0
        )
    }

    // MARK: - Coordinate

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude
        )
    }

    // MARK: - Total Vehicle

    /// Total kendaraan pada SATU interval CCTV.
    ///
    /// Contoh interval 7 menit:
    ///
    /// Mobil      = 20
    /// Motor      = 30
    /// Bus        = 2
    /// Truk       = 1
    ///
    /// Total      = 53 kendaraan
    ///
    /// Nilai ini tidak dikonversi ke kendaraan/jam.

    var totalVehicleCount: Int {
        carCount
        + motorcycleCount
        + busCount
        + truckCount
    }

    // MARK: - Emission Calculation

    /// Emisi mobil untuk SATU interval.

    private var carEmission: Double {
        Double(max(carCount, 0)) * Self.efCar
    }

    /// Emisi motor untuk SATU interval.

    private var motorcycleEmission: Double {
        Double(max(motorcycleCount, 0))
            * Self.efMotorcycle
    }

    /// Emisi bus untuk SATU interval.

    private var busEmission: Double {
        Double(max(busCount, 0))
            * Self.efBus
    }

    /// Emisi truk untuk SATU interval.

    private var truckEmission: Double {
        Double(max(truckCount, 0))
            * Self.efTruck
    }

    /// Total emission loading dari kendaraan
    /// pada interval saat ini.
    ///
    /// Satuan:
    /// mg/km

    var totalEmissionQ: Double {
        carEmission
        + motorcycleEmission
        + busEmission
        + truckEmission
    }

    // MARK: - Total Emission Mass

    /// Total massa emisi pada effective distance.
    ///
    /// mg/km × km = mg

    var totalEmissionMass: Double {

        let safeRoadLengthKm =
            max(roadLengthMeters, 1.0) / 1000.0

        return totalEmissionQ
            * safeRoadLengthKm
    }

    // MARK: - PM2.5 Calculation

    /// Menghitung PM2.5 untuk SATU interval CCTV.
    ///
    /// Default:
    /// 7 menit.
    ///
    /// VehicleCount yang diberikan ke fungsi ini
    /// harus merupakan kendaraan yang terdeteksi
    /// HANYA pada interval tersebut.
    ///
    /// Tidak ada:
    /// - kendaraan/jam
    /// - akumulasi interval sebelumnya
    /// - penjumlahan data interval sebelumnya
    ///
    /// Setiap pemanggilan fungsi merupakan
    /// perhitungan baru untuk interval tersebut.

    func predictedPM25C(
        vehicleCount: VehicleCount,
        windSpeed: Double,
        intervalMinutes: Int = 7
    ) -> Double {

        // -------------------------------------------------
        // 1. Pastikan interval valid.
        //
        // Default = 7 menit.
        //
        // Tidak ada konversi menjadi kendaraan/jam.
        // -------------------------------------------------

        let safeIntervalMinutes =
            max(intervalMinutes, 1)

        // -------------------------------------------------
        // 2. Ambil kendaraan dari INTERVAL SAAT INI.
        //
        // Data interval sebelumnya tidak ikut dihitung.
        // -------------------------------------------------

        let safeCar =
            max(vehicleCount.car, 0)

        let safeMotorcycle =
            max(vehicleCount.motorcycle, 0)

        let safeBus =
            max(vehicleCount.bus, 0)

        let safeTruck =
            max(vehicleCount.truck, 0)

        // -------------------------------------------------
        // 3. Hitung emission loading.
        //
        // Semua kendaraan hanya berasal dari
        // interval saat ini.
        //
        // Satuan:
        // mg/km
        // -------------------------------------------------

        let emissionPerKm =
            (Double(safeCar) * Self.efCar)
            + (Double(safeMotorcycle) * Self.efMotorcycle)
            + (Double(safeBus) * Self.efBus)
            + (Double(safeTruck) * Self.efTruck)

        // -------------------------------------------------
        // 4. Effective distance.
        //
        // Contoh:
        // 100 meter = 0.1 km
        // -------------------------------------------------

        let safeRoadLengthKm =
            max(roadLengthMeters, 1.0)
            / 1000.0

        // -------------------------------------------------
        // 5. Total massa emisi.
        //
        // mg/km × km = mg
        // -------------------------------------------------

        let totalMassMg =
            emissionPerKm
            * safeRoadLengthKm

        // -------------------------------------------------
        // 6. Interval 7 menit.
        //
        // 7 menit = 420 detik.
        //
        // Massa emisi interval dibagi dengan
        // durasi interval tersebut.
        //
        // Tidak menggunakan 1 jam.
        // -------------------------------------------------

        let intervalSeconds =
            Double(safeIntervalMinutes) * 60.0

        let emissionRateMgPerSecond =
            totalMassMg
            / intervalSeconds

        // -------------------------------------------------
        // 7. Box-model dispersion.
        //
        // C = Q / (U × H × W)
        //
        // Q = emission rate
        // U = wind speed
        // H = mixing height
        // W = street width
        // -------------------------------------------------

        let safeWindSpeed =
            max(windSpeed, 0.1)

        let safeMixingHeight =
            max(mixingHeight, 1.0)

        let safeStreetWidth =
            max(streetWidth, 1.0)

        let dispersionVolumePerSecond =
            safeWindSpeed
            * safeMixingHeight
            * safeStreetWidth

        let concentrationMgPerM3 =
            emissionRateMgPerSecond
            / dispersionVolumePerSecond

        // -------------------------------------------------
        // 8. mg/m³ → µg/m³
        // -------------------------------------------------

        let trafficPM25UgPerM3 =
            concentrationMgPerM3 * 1000.0

        // -------------------------------------------------
        // 9. Kalibrasi kontribusi kendaraan.
        // -------------------------------------------------

        let calibratedTrafficPM25 =
            trafficPM25UgPerM3
            * max(pm25CalibrationFactor, 0.0)

        // -------------------------------------------------
        // 10. Background PM2.5.
        //
        // Background tetap ada pada setiap interval.
        // Yang RESET setiap 7 menit adalah kontribusi
        // kendaraan karena vehicleCount berasal dari
        // interval baru.
        // -------------------------------------------------

        let finalPM25 =
            max(backgroundPM25, 0.0)
            + calibratedTrafficPM25

        // -------------------------------------------------
        // 11. Validasi angka.
        // -------------------------------------------------

        guard finalPM25.isFinite else {
            return max(backgroundPM25, 0.0)
        }

        return max(finalPM25, 0.0)
    }

    // MARK: - PM2.5 Convenience Calculation

    /// Menghitung PM2.5 menggunakan vehicle count
    /// yang tersimpan pada TrafficPoint.
    ///
    /// carCount, motorcycleCount, busCount dan
    /// truckCount dianggap sebagai DATA INTERVAL SAAT INI.
    ///
    /// Default interval = 7 menit.

    func predictedPM25C(
        windSpeed: Double,
        intervalMinutes: Int = 7
    ) -> Double {

        let vehicleCount = VehicleCount(
            car: max(carCount, 0),
            motorcycle: max(motorcycleCount, 0),
            bus: max(busCount, 0),
            truck: max(truckCount, 0)
        )

        return predictedPM25C(
            vehicleCount: vehicleCount,
            windSpeed: windSpeed,
            intervalMinutes: intervalMinutes
        )
    }

    // MARK: - PM2.5 Level

    enum PM25Level: String, Codable {

        case good
        case moderate
        case unhealthy

        var title: String {

            switch self {

            case .good:
                return "Baik"

            case .moderate:
                return "Sedang"

            case .unhealthy:
                return "Tidak Sehat"
            }
        }
    }

    // MARK: - PM2.5 Level Calculation

    static func level(
        for value: Double
    ) -> PM25Level {

        switch value {

        case 0..<35:
            return .good

        case 35..<55:
            return .moderate

        default:
            return .unhealthy
        }
    }

    var pm25Level: PM25Level {

        Self.level(
            for: predictedPM25C(
                windSpeed: windSpeed,
                intervalMinutes: 7
            )
        )
    }

    // MARK: - All Points

    static let all: [TrafficPoint] = [

        TrafficPoint(
            id: stableID("Baranangsiang"),
            locationName: "Baranangsiang",
            latitude: -6.6015,
            longitude: 106.8061,
            roadLengthMeters: 100.0,
            backgroundPM25: 10.0,
            pm25CalibrationFactor: 50.0
        ),

        TrafficPoint(
            id: stableID("Simpang Gadog"),
            locationName: "Simpang Gadog",
            latitude: -6.6572,
            longitude: 106.8525,
            roadLengthMeters: 100.0,
            backgroundPM25: 10.0,
            pm25CalibrationFactor: 50.0
        )
    ]

    // MARK: - Stable ID

    private static func stableID(
        _ value: String
    ) -> UUID {

        let data = Data(value.utf8)

        var hash: UInt64 =
            14695981039346656037

        for byte in data {

            hash ^= UInt64(byte)

            hash &*=
                1099511628211
        }

        let hex = String(
            format: "%016llx",
            hash
        )

        let repeated =
            (hex + hex + hex)
                .prefix(32)

        let string =
            String(repeated)

        let uuidString =
            "\(string.prefix(8))-" +
            "\(string.dropFirst(8).prefix(4))-" +
            "\(string.dropFirst(12).prefix(4))-" +
            "\(string.dropFirst(16).prefix(4))-" +
            "\(string.dropFirst(20).prefix(12))"

        return UUID(
            uuidString: uuidString
        ) ?? UUID()
    }
}
