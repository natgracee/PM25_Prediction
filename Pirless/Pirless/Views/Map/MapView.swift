//
//  MapView.swift
//  Pirless
//

import SwiftUI
import MapKit

struct MapView: View {

    // MARK: - Constants

    private let updateInterval: UInt64 =
        7 * 60 * 1_000_000_000

    // MARK: - State

    @State private var vehicleTraffic:
        [VehicleTrafficResponse] = []

    @State private var weatherData:
        [UUID: WeatherResponse] = [:]

    @State private var showingPM25Legend =
        false

    @State private var showingSearch =
        false

    @State private var cameraDistance:
        Double = 3000

    @State private var selectedPoint:
        TrafficPoint?

    @State private var cameraPosition:
        MapCameraPosition = .automatic

    @State private var isLoading =
        false

    // MARK: - Traffic Points

    private let points:
        [TrafficPoint] = TrafficPoint.all

    // MARK: - Body

    var body: some View {

        NavigationStack {

            ZStack {

                mapContent

                controls

                if isLoading {
                    loadingView
                }
            }
            .ignoresSafeArea(edges: .top)

            .sheet(
                isPresented:
                    $showingSearch
            ) {
                MapSearchView(
                    onSelectLocation:
                        moveCamera(
                            to:distance:
                        )
                )
                .presentationDragIndicator(
                    .visible
                )
            }

            .navigationDestination(
                item:
                    $selectedPoint
            ) { point in

                destinationView(
                    for: point
                )
            }
        }

        .task {
            await loadMapDataLoop()
        }
    }
}

// MARK: - Update Loop

private extension MapView {

    func loadMapDataLoop() async {

        while !Task.isCancelled {

            await loadMapData()

            do {

                try await Task.sleep(
                    nanoseconds:
                        updateInterval
                )

            } catch {

                break
            }
        }
    }
}

// MARK: - Load Map Data

private extension MapView {

    func loadMapData() async {

        await MainActor.run {
            isLoading = true
        }

        async let vehicleTask =
            fetchVehicleData()

        async let weatherTask =
            fetchWeatherData()

        let vehicles =
            await vehicleTask

        let weather =
            await weatherTask

        guard !Task.isCancelled else {

            await MainActor.run {
                isLoading = false
            }

            return
        }

        await MainActor.run {

            vehicleTraffic =
                vehicles

            weatherData =
                weather
        }

        // Simpan batch data yang BARU
        // menggunakan kendaraan + weather
        // pada siklus yang sama.

        saveReadingsToHistory(
            vehicles: vehicles,
            weather: weather
        )

        await MainActor.run {
            isLoading = false
        }
    }
}

// MARK: - Fetch Vehicle Data

private extension MapView {

    func fetchVehicleData()
        async -> [VehicleTrafficResponse]
    {

        do {

            let vehicles =
                try await APIClient.shared
                    .fetchVehicleTraffic()

            print("")
            print(
                "========================================"
            )
            print(
                "📍 MAP VEHICLE DATA LOADED"
            )
            print(
                "Jumlah data: \(vehicles.count)"
            )
            print(
                "========================================"
            )

            for vehicle in vehicles {

                print(
                    """
                    CAMERA:
                    \(vehicle.kamera)

                    LOKASI:
                    \(vehicle.lokasi)

                    INTERVAL:
                    \(vehicle.intervalMenit) menit

                    MULAI:
                    \(vehicle.mulai)

                    SELESAI:
                    \(vehicle.selesai)

                    MOTOR:
                    \(vehicle.volumeKendaraan.motor)

                    MOBIL:
                    \(vehicle.volumeKendaraan.mobil)

                    BUS:
                    \(vehicle.volumeKendaraan.bus)

                    TRUK:
                    \(vehicle.volumeKendaraan.truk)

                    TOTAL:
                    \(vehicle.total)
                    """
                )

                print(
                    "----------------------------------------"
                )
            }

            return vehicles

        } catch {

            print("")
            print(
                "========================================"
            )
            print(
                "❌ MAP VEHICLE DATA FAILED"
            )
            print(
                "========================================"
            )
            print(
                error.localizedDescription
            )
            print(
                "========================================"
            )

            return []
        }
    }
}

// MARK: - Fetch Weather Data

private extension MapView {

    func fetchWeatherData()
        async -> [UUID: WeatherResponse]
    {

        var result:
            [UUID: WeatherResponse] = [:]

        await withTaskGroup(
            of:
                (UUID, WeatherResponse?).self
        ) { group in

            for point in points {

                group.addTask {

                    do {

                        let weather =
                            try await APIClient.shared
                                .fetchWeather(
                                    latitude:
                                        point.latitude,
                                    longitude:
                                        point.longitude
                                )

                        return (
                            point.id,
                            weather
                        )

                    } catch {

                        print(
                            "❌ WEATHER FAILED \(point.locationName):",
                            error.localizedDescription
                        )

                        return (
                            point.id,
                            nil
                        )
                    }
                }
            }

            for await (
                pointID,
                weather
            ) in group {

                if let weather {

                    result[pointID] =
                        weather
                }
            }
        }

        return result
    }
}

// MARK: - Camera Name Normalization

private extension MapView {

    /// Menyamakan format nama kamera
    /// supaya:
    ///
    /// "Simpang Gadog"
    /// "simpang gadog"
    /// "SIMPANG GADOG "
    ///
    /// tetap dianggap sama.

    func normalizedName(
        _ value: String
    ) -> String {

        let normalized =
            value
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
                .folding(
                    options:
                        [
                            .caseInsensitive,
                            .diacriticInsensitive
                        ],
                    locale:
                        .current
                )
                .lowercased()

        // Alias nama lokasi dari API.
        //
        // TrafficPoint:
        // "Simpang Gadog"
        //
        // API:
        // "Simpang Gadong"
        //
        // Keduanya dianggap sebagai lokasi yang sama.

        switch normalized {

        case "simpang gadong":
            return "simpang gadog"

        default:
            return normalized
        }
    }
}

// MARK: - Traffic Lookup

private extension MapView {

    /// Mengambil data kendaraan TERBARU
    /// untuk satu TrafficPoint.
    ///
    /// Prioritas pencocokan:
    ///
    /// 1. kamera == locationName
    /// 2. kamera mengandung locationName
    /// 3. lokasi mengandung locationName

    func traffic(
        for point: TrafficPoint
    ) -> VehicleTrafficResponse? {

        traffic(
            for: point,
            from: vehicleTraffic
        )
    }

    func traffic(
        for point: TrafficPoint,
        from vehicles:
            [VehicleTrafficResponse]
    ) -> VehicleTrafficResponse? {

        let pointName =
            normalizedName(
                point.locationName
            )

        // ------------------------------------------------
        // 1. EXACT CAMERA MATCH
        // ------------------------------------------------

        let exactCamera =
            vehicles.filter { vehicle in

                normalizedName(
                    vehicle.kamera
                ) == pointName
            }

        if let latest =
            exactCamera.max(
                by: {
                    timeInSeconds(
                        $0.mulai
                    )
                    <
                    timeInSeconds(
                        $1.mulai
                    )
                }
            ) {

            print(
                "✅ EXACT MATCH:",
                point.locationName,
                "<->",
                latest.kamera
            )

            return latest
        }

        // ------------------------------------------------
        // 2. CAMERA CONTAINS MATCH
        // ------------------------------------------------

        let containsCamera =
            vehicles.filter { vehicle in

                let cameraName =
                    normalizedName(
                        vehicle.kamera
                    )

                return
                    cameraName.contains(
                        pointName
                    )
                    ||
                    pointName.contains(
                        cameraName
                    )
            }

        if let latest =
            containsCamera.max(
                by: {
                    timeInSeconds(
                        $0.mulai
                    )
                    <
                    timeInSeconds(
                        $1.mulai
                    )
                }
            ) {

            print(
                "✅ CAMERA CONTAINS MATCH:",
                point.locationName,
                "<->",
                latest.kamera
            )

            return latest
        }

        // ------------------------------------------------
        // 3. LOKASI MATCH
        // ------------------------------------------------

        let locationMatch =
            vehicles.filter { vehicle in

                let location =
                    normalizedName(
                        vehicle.lokasi
                    )

                return
                    location.contains(
                        pointName
                    )
                    ||
                    pointName.contains(
                        location
                    )
            }

        if let latest =
            locationMatch.max(
                by: {
                    timeInSeconds(
                        $0.mulai
                    )
                    <
                    timeInSeconds(
                        $1.mulai
                    )
                }
            ) {

            print(
                "✅ LOCATION MATCH:",
                point.locationName,
                "<->",
                latest.lokasi
            )

            return latest
        }

        // ------------------------------------------------
        // NO MATCH
        // ------------------------------------------------

        print(
            "❌ NO TRAFFIC MATCH:",
            point.locationName
        )

        print(
            "Available cameras:"
        )

        for vehicle in vehicles {

            print(
                " - \(vehicle.kamera)"
            )
        }

        return nil
    }

    func timeInSeconds(
        _ time: String
    ) -> Int {

        let components =
            time.split(
                separator: ":"
            )

        guard
            components.count == 3,
            let hour =
                Int(components[0]),
            let minute =
                Int(components[1]),
            let second =
                Int(components[2])
        else {

            return 0
        }

        return
            hour * 3600
            + minute * 60
            + second
    }
}

// MARK: - PM2.5

private extension MapView {

    /// PM2.5 dihitung berdasarkan:
    ///
    /// - batch kendaraan TERBARU
    /// - interval CCTV aktual
    /// - weather aktual
    ///
    /// Tidak mengambil carCount/busCount
    /// dari TrafficPoint.

    func pm25(
        for point: TrafficPoint
    ) -> Double {

        guard
            let traffic =
                traffic(for: point)
        else {

            return 0
        }

        let vehicleCount =
            traffic.vehicleCount

        let windSpeed =
            weatherData[point.id]?
                .current
                .windSpeed10m
            ?? point.windSpeed

        return
            point.predictedPM25C(
                vehicleCount:
                    vehicleCount,
                windSpeed:
                    windSpeed, intervalMinutes:
                    traffic.intervalMenit
            )
    }

    /// Interval PM2.5 mengikuti interval
    /// CCTV yang digunakan untuk perhitungan.

    func pm25Interval(
        for point: TrafficPoint
    ) -> Int {

        traffic(
            for: point
        )?.intervalMenit ?? 0
    }
}

// MARK: - Save History

private extension MapView {

    func saveReadingsToHistory(
        vehicles:
            [VehicleTrafficResponse],
        weather:
            [UUID: WeatherResponse]
    ) {

        guard !vehicles.isEmpty else {
            return
        }

        guard !weather.isEmpty else {
            return
        }

        let timestamp =
            Date()

        var newReadings:
            [AirQualityReading] = []

        for point in points {

            // --------------------------------------------
            // TRAFFIC TERBARU
            // --------------------------------------------

            guard
                let traffic =
                    traffic(
                        for: point,
                        from: vehicles
                    )
            else {

                print(
                    "⚠️ HISTORY SKIP TRAFFIC:",
                    point.locationName
                )

                continue
            }

            // --------------------------------------------
            // WEATHER
            // --------------------------------------------

            guard
                let currentWeather =
                    weather[point.id]
            else {

                print(
                    "⚠️ HISTORY SKIP WEATHER:",
                    point.locationName
                )

                continue
            }

            // --------------------------------------------
            // VEHICLE COUNT
            // --------------------------------------------

            let vehicleCount =
                traffic.vehicleCount

            // --------------------------------------------
            // WIND
            // --------------------------------------------

            let windSpeed =
                currentWeather
                    .current
                    .windSpeed10m

            // --------------------------------------------
            // PM2.5
            // --------------------------------------------

            let calculatedPM25 =
                point.predictedPM25C(
                    vehicleCount:
                        vehicleCount,
                    windSpeed:
                        windSpeed, intervalMinutes:
                        traffic.intervalMenit
                )

            // --------------------------------------------
            // READING
            // --------------------------------------------

            let reading =
                AirQualityReading(
                    trafficPointId:
                        point.id,

                    timestamp:
                        timestamp,

                    pm25:
                        calculatedPM25,

                    pm25IntervalMinutes:
                        traffic.intervalMenit,

                    windSpeed:
                        windSpeed,

                    humidity:
                        currentWeather
                            .current
                            .relativeHumidity2m,

                    vehicleCount:
                        vehicleCount
                )

            newReadings.append(
                reading
            )

            print(
                """
                💾 HISTORY READING

                Point:
                \(point.locationName)

                Camera:
                \(traffic.kamera)

                Interval:
                \(traffic.intervalMenit) menit

                Mulai:
                \(traffic.mulai)

                Selesai:
                \(traffic.selesai)

                Motor:
                \(vehicleCount.motorcycle)

                Mobil:
                \(vehicleCount.car)

                Bus:
                \(vehicleCount.bus)

                Truk:
                \(vehicleCount.truck)

                Total:
                \(vehicleCount.total)

                Wind:
                \(windSpeed) m/s

                PM2.5:
                \(calculatedPM25)
                """
            )

            print(
                "========================================"
            )
        }

        guard !newReadings.isEmpty else {
            return
        }

        Task { @MainActor in

            HistoryStore.shared.add(
                contentsOf:
                    newReadings
            )
        }
    }
}

// MARK: - Navigation Destination

private extension MapView {

    @ViewBuilder
    func destinationView(
        for point: TrafficPoint
    ) -> some View {

        if
            let traffic =
                traffic(for: point),
            let weather =
                weatherData[point.id]
        {

            PointDetailView(
                trafficPoint:
                    point,
                traffic:
                    traffic,
                weather:
                    weather
            )

        } else {

            VStack(
                spacing: 12
            ) {

                ProgressView()

                Text(
                    "Data belum tersedia"
                )
                .foregroundStyle(
                    .secondary
                )

                // Debug tambahan
                if vehicleTraffic.isEmpty {

                    Text(
                        "Data kendaraan belum diterima dari server."
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )

                } else {

                    Text(
                        "Data CCTV untuk \(point.locationName) belum ditemukan."
                    )
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Map

private extension MapView {

    var mapContent: some View {

        Map(
            position:
                $cameraPosition
        ) {

            ForEach(
                points
            ) { point in

                PM25SpreadOverlay(
                    coordinate:
                        point.coordinate,

                    directionDegrees:
                        90,

                    lengthMeters:
                        100,

                    visibility:
                        spreadVisibility
                )

                Annotation(
                    "",
                    coordinate:
                        point.coordinate
                ) {

                    ZStack {

                        PM25SpreadAnimation(
                            directionDegrees:
                                90,

                            visibility:
                                spreadVisibility
                        )

                        PM25RadarPulse(
                            color:
                                markerColor(
                                    for:
                                        point
                                ),

                            scale:
                                radarScale,

                            visibility:
                                radarVisibility
                        )

                        marker(
                            for:
                                point
                        )
                    }
                }
            }

            UserAnnotation()
        }

        .mapStyle(
            .standard
        )

        .onMapCameraChange(
            frequency:
                .onEnd
        ) { context in

            cameraDistance =
                context.camera.distance
        }
    }

    func moveCamera(
        to coordinate:
            CLLocationCoordinate2D,
        distance:
            Double
    ) {

        withAnimation {

            cameraDistance =
                distance

            cameraPosition =
                .camera(
                    MapCamera(
                        centerCoordinate:
                            coordinate,

                        distance:
                            distance
                    )
                )
        }
    }
}

// MARK: - Marker

private extension MapView {

    @ViewBuilder
    func marker(
        for point: TrafficPoint
    ) -> some View {

        let currentPM25 =
            pm25(
                for:
                    point
            )

        let intervalMinutes =
            pm25Interval(
                for:
                    point
            )

        Button {

            selectedPoint =
                point

        } label: {

            PM25MapMarker(
                value:
                    currentPM25
            )
            .frame(
                width:
                    64,
                height:
                    64
            )
            .contentShape(
                Circle()
            )
        }

        .buttonStyle(
            MarkerButtonStyle()
        )

        .accessibilityLabel(
            point.locationName
        )

        .accessibilityValue(
            """
            Estimasi PM2.5
            \(String(format: "%.2f", currentPM25))
            µg/m³ selama
            \(intervalMinutes)
            menit
            """
        )

        .accessibilityHint(
            "Ketuk untuk melihat detail kualitas udara"
        )
    }
}

// MARK: - Marker Color

private extension MapView {

    func markerColor(
        for point: TrafficPoint
    ) -> Color {

        let currentPM25 =
            pm25(
                for:
                    point
            )

        switch TrafficPoint.level(for: currentPM25) {
            case .good:
                return .green

            case .moderate:
                return .yellow

            case .unhealthy:
                return .red
            }
    }
}



// MARK: - Radar Scale

private extension MapView {

    var radarScale: CGFloat {

        switch cameraDistance {

        case 0...2_500:
            return 0.55

        case 2_500...5_000:
            return 0.75

        case 5_000...10_000:
            return 1.0

        case 10_000...25_000:
            return 1.15

        default:
            return 1.25
        }
    }

    var radarVisibility: Double {

        switch cameraDistance {

        case 0...2_500:
            return 0.12

        case 2_500...5_000:
            return 0.18

        case 5_000...10_000:
            return 0.24

        case 10_000...25_000:
            return 0.18

        default:
            return 0.10
        }
    }

    var spreadVisibility: Double {

        switch cameraDistance {

        case 0...2_500:
            return 1.0

        case 2_500...5_000:
            return 0.65

        case 5_000...10_000:
            return 0.30

        case 10_000...25_000:
            return 0.10

        default:
            return 0.03
        }
    }
}

// MARK: - Loading

private extension MapView {

    var loadingView: some View {

        VStack {

            Spacer()

            HStack(
                spacing: 10
            ) {

                ProgressView()

                Text(
                    "Memuat data..."
                )
                .font(
                    .footnote.weight(
                        .medium
                    )
                )
            }

            .padding(
                .horizontal,
                16
            )

            .padding(
                .vertical,
                10
            )

            .background(
                .thinMaterial,
                in:
                    Capsule()
            )

            Spacer()
                .frame(
                    height:
                        80
                )
        }
    }
}

// MARK: - Controls

private extension MapView {

    var controls: some View {

        VStack {

            topControls

            Spacer()

            searchButton
        }
    }

    var topControls: some View {

        HStack {

            if showingPM25Legend {

                PM25LegendView {

                    withAnimation(
                        .easeOut(
                            duration:
                                0.15
                        )
                    ) {

                        showingPM25Legend =
                            false
                    }
                }

                .transition(
                    .opacity
                        .combined(
                            with:
                                .scale(
                                    scale:
                                        0.95
                                )
                        )
                )

            } else {

                infoButton

                    .transition(
                        .opacity
                            .combined(
                                with:
                                    .scale(
                                        scale:
                                            0.95
                                    )
                            )
                    )
            }

            Spacer()
        }

        .padding(
            .horizontal,
            16
        )

        .safeAreaPadding(
            .top,
            60
        )
    }

    var infoButton: some View {

        Button {

            withAnimation(
                .easeOut(
                    duration:
                        0.15
                )
            ) {

                showingPM25Legend =
                    true
            }

        } label: {

            Image(
                systemName:
                    "info.circle"
            )

            .font(
                .system(
                    size:
                        20,
                    weight:
                        .bold
                )
            )

            .foregroundStyle(
                .primary
            )

            .frame(
                width:
                    44,
                height:
                    44
            )
        }

        .buttonStyle(
            .plain
        )

        .glassEffect(
            in:
                Circle()
        )

        .accessibilityLabel(
            "Informasi PM2.5"
        )

        .accessibilityHint(
            "Menampilkan informasi kategori PM2.5"
        )
    }

    var searchButton: some View {

        Button {

            showingSearch =
                true

        } label: {

            HStack(
                spacing:
                    10
            ) {

                Image(
                    systemName:
                        "magnifyingglass"
                )

                .font(
                    .body.weight(
                        .medium
                    )
                )

                Text(
                    "Search Area"
                )
                .font(
                    .body
                )

                Spacer()

                Image(
                    systemName:
                        "mic.fill"
                )
                .font(
                    .body
                )
            }

            .foregroundStyle(
                .secondary
            )

            .padding(
                .horizontal,
                16
            )

            .frame(
                minHeight:
                    52
            )
        }

        .buttonStyle(
            .plain
        )

        .glassEffect(
            in:
                Capsule()
        )

        .accessibilityLabel(
            "Search Area"
        )

        .accessibilityHint(
            "Mencari lokasi"
        )

        .padding(
            .horizontal,
            20
        )

        .padding(
            .bottom,
            12
        )
    }
}

// MARK: - Marker Button Style

private struct MarkerButtonStyle:
    ButtonStyle {

    func makeBody(
        configuration:
            Configuration
    ) -> some View {

        configuration.label

            .scaleEffect(
                configuration.isPressed
                    ? 0.88
                    : 1.0
            )

            .opacity(
                configuration.isPressed
                    ? 0.75
                    : 1.0
            )

            .animation(
                .easeOut(
                    duration:
                        0.12
                ),
                value:
                    configuration.isPressed
            )
    }
}

// MARK: - Preview

#Preview {

    MapView()
}
