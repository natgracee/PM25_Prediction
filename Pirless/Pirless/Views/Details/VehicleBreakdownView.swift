//
//  VehicleBreakdownView.swift
//  Pirless
//
//  Created by M. TAQWA ADDARI on 17/08/26.
//

import SwiftUI

/// Compact vehicle-count list card shown on the Detail screen.
///
/// NOTE: The Figma reference draws the section title ("Vehicle Breakdown")
/// as a standalone heading *outside* this card, with the card itself
/// containing only the tight row list. The heading now lives in
/// `Detail.swift` (`vehicleBreakdownSection`) so this view stays a plain
/// reusable list card. Rows also use the system font (SF Pro) rather than
/// a custom font, per the "no custom font" implementation decision.
struct VehicleBreakdownView: View {

    let vehicles: [VehicleItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {

            ForEach(vehicles) { vehicle in

                HStack(spacing: 8) {

                    Image(systemName: vehicle.systemImage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.cyan)
                        .frame(width: 16)

                    Text(vehicle.name)
                        .font(.subheadline)
                        .foregroundStyle(.primary)

                    Spacer(minLength: 8)

                    Text("\(vehicle.count)")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
                .frame(minHeight: 24)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    "\(vehicle.name): \(vehicle.count) kendaraan per jam"
                )
            }
        }
        .padding(17)
        .frame(maxWidth: .infinity)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(
                cornerRadius: 12,
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
