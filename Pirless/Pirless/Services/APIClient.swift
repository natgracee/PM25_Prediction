//
//  APIClient.swift
//  Pirless
//

import Foundation

final class APIClient {

    static let shared = APIClient()

    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default

        // Batas waktu request agar tidak loading terlalu lama
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 15

        self.session = URLSession(
            configuration: configuration
        )
    }

    // MARK: - Backend

    var backendBaseURL: String =
        "https://capsule-favored-eclair.ngrok-free.dev"

    // MARK: - Vehicle Traffic

    func fetchVehicleTraffic()
        async throws -> [VehicleTrafficResponse]
    {
        let urlString = backendBaseURL + "/"

        guard let url = URL(string: urlString) else {
            throw APIClientError.invalidURL
        }

        var request = URLRequest(url: url)

        request.httpMethod = "GET"

        request.setValue(
            "true",
            forHTTPHeaderField: "ngrok-skip-browser-warning"
        )

        print("")
        print("========================================")
        print("🚗 FETCH VEHICLE TRAFFIC")
        print("========================================")
        print(url.absoluteString)
        print("========================================")

        do {
            let (data, response) =
                try await session.data(
                    for: request
                )

            guard let httpResponse =
                    response as? HTTPURLResponse
            else {
                throw APIClientError.invalidResponse
            }

            print(
                "Vehicle Traffic HTTP Status: \(httpResponse.statusCode)"
            )

            guard (200...299).contains(
                httpResponse.statusCode
            ) else {
                throw APIClientError.httpError(
                    httpResponse.statusCode
                )
            }

            let result =
                try JSONDecoder().decode(
                    [VehicleTrafficResponse].self,
                    from: data
                )

            print("")
            print("========================================")
            print("✅ VEHICLE DATA DECODED")
            print("Jumlah data: \(result.count)")
            print("========================================")

            return result

        } catch let error as APIClientError {
            throw error

        } catch {
            print(
                "❌ Vehicle traffic error:",
                error.localizedDescription
            )

            throw APIClientError.decodingError
        }
    }

    // MARK: - Open-Meteo

    func fetchWeather(
        latitude: Double,
        longitude: Double
    ) async throws -> WeatherResponse {

        var components =
            URLComponents(
                string:
                    "https://api.open-meteo.com/v1/forecast"
            )

        components?.queryItems = [

            URLQueryItem(
                name: "latitude",
                value: String(latitude)
            ),

            URLQueryItem(
                name: "longitude",
                value: String(longitude)
            ),

            URLQueryItem(
                name: "current",
                value:
                    "temperature_2m,wind_speed_10m,relative_humidity_2m"
            ),

            URLQueryItem(
                name: "wind_speed_unit",
                value: "ms"
            )
        ]

        guard let url = components?.url else {
            throw APIClientError.invalidURL
        }

        print("")
        print("========================================")
        print("🌤️ OPEN-METEO API REQUEST")
        print("========================================")
        print(
            "Location: \(latitude), \(longitude)"
        )
        print("========================================")

        do {
            let (data, response) =
                try await session.data(
                    from: url
                )

            guard let httpResponse =
                    response as? HTTPURLResponse
            else {
                throw APIClientError.invalidResponse
            }

            print(
                "Open-Meteo HTTP Status: \(httpResponse.statusCode)"
            )

            guard (200...299).contains(
                httpResponse.statusCode
            ) else {
                throw APIClientError.httpError(
                    httpResponse.statusCode
                )
            }

            let result =
                try JSONDecoder().decode(
                    WeatherResponse.self,
                    from: data
                )

            print("")
            print("========================================")
            print("✅ OPEN-METEO DATA DECODED")
            print("Temperature: \(result.current.temperature2m) °C")
            print("Humidity: \(result.current.relativeHumidity2m) %")
            print("Wind: \(result.current.windSpeed10m) m/s")
            print("========================================")

            return result

        } catch let error as APIClientError {
            throw error

        } catch {
            print(
                "❌ Open-Meteo error:",
                error.localizedDescription
            )

            throw APIClientError.decodingError
        }
    }
}

// MARK: - Weather Response

struct WeatherResponse: Codable {

    let current: CurrentWeather
}

struct CurrentWeather: Codable {

    let time: String
    let interval: Int

    let temperature2m: Double
    let windSpeed10m: Double
    let relativeHumidity2m: Double

    enum CodingKeys: String, CodingKey {

        case time
        case interval

        case temperature2m =
            "temperature_2m"

        case windSpeed10m =
            "wind_speed_10m"

        case relativeHumidity2m =
            "relative_humidity_2m"
    }
}

// MARK: - API Error

enum APIClientError: LocalizedError {

    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError

    var errorDescription: String? {

        switch self {

        case .invalidURL:
            return "URL tidak valid."

        case .invalidResponse:
            return "Response server tidak valid."

        case .httpError(let status):
            return "HTTP error: \(status)"

        case .decodingError:
            return "Data server tidak dapat dibaca."
        }
    }
}
