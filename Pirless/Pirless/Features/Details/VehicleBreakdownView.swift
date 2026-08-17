//
//  VehicleBreakdownView.swift
//  Pirless
//
//  Created by M. TAQWA ADDARI on 17/08/26.
//


import SwiftUI

struct VehicleBreakdownView: View {

    let vehicles: [VehicleItem]

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            Text("Vehicle Breakdown")
                .font(
                    .system(
                        size: 22,
                        weight: .bold
                    )
                )
                .padding(
                    .horizontal,
                    20
                )
                .padding(
                    .vertical,
                    18
                )

            Divider()

            ForEach(vehicles) { vehicle in

                HStack(spacing: 16) {

                    Image(systemName: vehicle.systemImage)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.cyan)
                        .frame(width: 40)

                    Text(vehicle.name)
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 8)

                    Text("\(vehicle.count)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.primary)
                        .frame(width: 55, alignment: .trailing)

                    Text("kend/jam")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .frame(width: 70, alignment: .leading)
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, minHeight: 60)

                if vehicle.id != vehicles.last?.id {
                    Divider()
                        .padding(.leading, 20)
                }
            }
        }
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
    }
}

// MARK: - Model

struct VehicleItem: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
    let systemImage: String
    let color: Color
}

// MARK: - Preview

// MARK: - Preview

#Preview {
    VehicleBreakdownView(
        vehicles: [
            VehicleItem(
                name: "Mobil",
                count: 200,
                systemImage: "car.fill",
                color: .green
            ),
            VehicleItem(
                name: "Motor",
                count: 900,
                systemImage: "motorcycle.fill",
                color: .purple
            ),
            VehicleItem(
                name: "Bus",
                count: 18,
                systemImage: "bus.fill",
                color: .blue
            ),
            VehicleItem(
                name: "Truk",
                count: 6,
                systemImage: "truck.box.fill",
                color: .orange
            )
        ]
    )
    .padding()
    .background(
        Color(.systemGroupedBackground)
    )
}
