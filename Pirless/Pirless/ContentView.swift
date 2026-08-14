//
//  ContentView.swift
//  Pirless
//
//  Created by Muh. Naufal Fahri Salim on 8/13/26.
//

import SwiftUI

struct ContentView: View {
    // mock data
    @State private var cctvTesting = TrafficPoint(
        locationName: "Lampung",
        carCount: 150,
        motorcycleCount: 350,
        busCount: 20,
        truckCount: 5,
        windSpeed: 2.5  // default
    )

    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Lokasi: \(cctvTesting.locationName)")
                Text("Mobil: \(cctvTesting.carCount)")
                Text("Motor: \(cctvTesting.motorcycleCount)")
                Text("Bus: \(cctvTesting.busCount)")
                Text("Truk: \(cctvTesting.truckCount)")
                Text(
                    "Kecepatan Angin (U): \(String(format: "%.1f", cctvTesting.windSpeed)) m/s"
                )
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)

            VStack(alignment: .center, spacing: 10) {
                Text("Hasil Kalkulasi:")
                    .font(.headline)

                Text(
                    "Total Emisi (Q) = \(String(format: "%.2f", cctvTesting.totalEmissionQ))"
                )

                Text(
                    "Prediksi PM2.5 (C) = \(String(format: "%.6f", cctvTesting.predictedPM25C))"
                )
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
