//
//  MapViewModel.swift
//  Pirless
//

import SwiftUI
import MapKit

@Observable
@MainActor
final class MapViewModel {

    // MARK: - State

    var vehicleTraffic: [VehicleTrafficResponse] = []
    var weatherData: [UUID: WeatherResponse] = [:]
    var showingPM25Legend = false
    var showingSearch = false
    var cameraDistance: Double = 3000
    var selectedPoint: TrafficPoint? = nil
    var cameraPosition: MapCameraPosition = .automatic
    var isLoading = false

    // MARK: - Constants

    let points: [TrafficPoint] = TrafficPoint.all
    let updateInterval: UInt64 = 7 * 60 * 1_000_000_000

    // MARK: - Update Loop

    func loadMapDataLoop() async {
        while !Task.isCancelled {
            await loadMapData()
            do {
                try await Task.sleep(nanoseconds: updateInterval)
            } catch {
                break
            }
        }
    }

    // MARK: - Load Map Data

    func loadMapData() async {
        isLoading = true

        async let vehicleTask = fetchVehicleData()
        async let weatherTask = fetchWeatherData()

        let vehicles = await vehicleTask
        let weather = await weatherTask

        guard !Task.isCancelled else {
            isLoading = false
            return
        }

        vehicleTraffic = vehicles
        weatherData = weather

        saveReadingsToHistory(vehicles: vehicles, weather: weather)

        isLoading = false
    }

    // MARK: - Fetch Vehicle Data

    func fetchVehicleData() async -> [VehicleTrafficResponse] {
        do {
            return try await APIClient.shared.fetchVehicleTraffic()
        } catch {
            print("❌ MAP VEHICLE DATA FAILED:", error.localizedDescription)
            return []
        }
    }

    // MARK: - Fetch Weather Data

    func fetchWeatherData() async -> [UUID: WeatherResponse] {
        var result: [UUID: WeatherResponse] = [:]

        await withTaskGroup(of: (UUID, WeatherResponse?).self) { group in
            for point in points {
                group.addTask {
                    do {
                        let weather = try await APIClient.shared.fetchWeather(
                            latitude: point.latitude,
                            longitude: point.longitude
                        )
                        return (point.id, weather)
                    } catch {
                        print("❌ WEATHER FAILED \(point.locationName):", error.localizedDescription)
                        return (point.id, nil)
                    }
                }
            }

            for await (pointID, weather) in group {
                if let weather {
                    result[pointID] = weather
                }
            }
        }

        return result
    }

    // MARK: - Camera Name Normalization

    func normalizedName(_ value: String) -> String {
        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()

        switch normalized {
        case "simpang gadong":
            return "simpang gadog"
        default:
            return normalized
        }
    }

    // MARK: - Traffic Lookup

    func traffic(for point: TrafficPoint) -> VehicleTrafficResponse? {
        traffic(for: point, from: vehicleTraffic)
    }

    func traffic(
        for point: TrafficPoint,
        from vehicles: [VehicleTrafficResponse]
    ) -> VehicleTrafficResponse? {

        let pointName = normalizedName(point.locationName)

        let exactCamera = vehicles.filter {
            normalizedName($0.kamera) == pointName
        }
        if let latest = exactCamera.max(by: { timeInSeconds($0.mulai) < timeInSeconds($1.mulai) }) {
            return latest
        }

        let containsCamera = vehicles.filter { vehicle in
            let cameraName = normalizedName(vehicle.kamera)
            return cameraName.contains(pointName) || pointName.contains(cameraName)
        }
        if let latest = containsCamera.max(by: { timeInSeconds($0.mulai) < timeInSeconds($1.mulai) }) {
            return latest
        }

        let locationMatch = vehicles.filter { vehicle in
            let location = normalizedName(vehicle.lokasi)
            return location.contains(pointName) || pointName.contains(location)
        }
        if let latest = locationMatch.max(by: { timeInSeconds($0.mulai) < timeInSeconds($1.mulai) }) {
            return latest
        }

        return nil
    }

    func timeInSeconds(_ time: String) -> Int {
        let components = time.split(separator: ":")
        guard
            components.count == 3,
            let hour = Int(components[0]),
            let minute = Int(components[1]),
            let second = Int(components[2])
        else { return 0 }
        return hour * 3600 + minute * 60 + second
    }

    // MARK: - PM2.5

    func pm25(for point: TrafficPoint) -> Double {
        guard let traffic = traffic(for: point) else { return 0 }
        let windSpeed = weatherData[point.id]?.current.windSpeed10m ?? point.windSpeed
        return point.predictedPM25C(
            vehicleCount: traffic.vehicleCount,
            windSpeed: windSpeed,
            intervalMinutes: traffic.intervalMenit
        )
    }

    func pm25Interval(for point: TrafficPoint) -> Int {
        traffic(for: point)?.intervalMenit ?? 0
    }

    // MARK: - Save History

    func saveReadingsToHistory(
        vehicles: [VehicleTrafficResponse],
        weather: [UUID: WeatherResponse]
    ) {
        guard !vehicles.isEmpty, !weather.isEmpty else { return }

        let timestamp = Date()
        var newReadings: [AirQualityReading] = []

        for point in points {
            guard let traffic = traffic(for: point, from: vehicles) else { continue }
            guard let currentWeather = weather[point.id] else { continue }

            let vehicleCount = traffic.vehicleCount
            let windSpeed = currentWeather.current.windSpeed10m

            let calculatedPM25 = point.predictedPM25C(
                vehicleCount: vehicleCount,
                windSpeed: windSpeed,
                intervalMinutes: traffic.intervalMenit
            )

            let reading = AirQualityReading(
                trafficPointId: point.id,
                timestamp: timestamp,
                pm25: calculatedPM25,
                pm25IntervalMinutes: traffic.intervalMenit,
                windSpeed: windSpeed,
                humidity: currentWeather.current.relativeHumidity2m,
                vehicleCount: vehicleCount
            )

            newReadings.append(reading)
        }

        guard !newReadings.isEmpty else { return }
        HistoryStore.shared.add(contentsOf: newReadings)
    }

    // MARK: - Camera

    func moveCamera(to coordinate: CLLocationCoordinate2D, distance: Double) {
        withAnimation {
            cameraDistance = distance
            cameraPosition = .camera(
                MapCamera(centerCoordinate: coordinate, distance: distance)
            )
        }
    }

    // MARK: - Marker Color

    func markerColor(for point: TrafficPoint) -> Color {
        switch TrafficPoint.level(for: pm25(for: point)) {
        case .good:     return .green
        case .moderate: return .yellow
        case .unhealthy: return .red
        }
    }

    // MARK: - Radar Scale

    var radarScale: CGFloat {
        switch cameraDistance {
        case 0...2_500:     return 0.55
        case 2_500...5_000: return 0.75
        case 5_000...10_000: return 1.0
        case 10_000...25_000: return 1.15
        default:            return 1.25
        }
    }

    var radarVisibility: Double {
        switch cameraDistance {
        case 0...2_500:     return 0.12
        case 2_500...5_000: return 0.18
        case 5_000...10_000: return 0.24
        case 10_000...25_000: return 0.18
        default:            return 0.10
        }
    }

    var spreadVisibility: Double {
        switch cameraDistance {
        case 0...2_500:     return 1.0
        case 2_500...5_000: return 0.65
        case 5_000...10_000: return 0.30
        case 10_000...25_000: return 0.10
        default:            return 0.03
        }
    }
}
