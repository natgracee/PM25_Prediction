//
//  VehicleBreakdownView.swift
//  Pirless
//
//  Created by M. TAQWA ADDARI on 17/08/26.
//
//  Merged version:
//  - Data: takes the real `VehicleTrafficResponse` directly (like the
//    original real-data implementation) and derives `vehicleItems`
//    internally, instead of requiring the caller to pre-build a
//    [VehicleItem] array.
//  - UI: the compact list-card layout from the Figma-based revision —
//    no per-row divider, uniform cyan icon color, no "kend/jam" unit
//    label, and no internal heading. The "Vehicle Breakdown" section
//    title lives outside this view (see PointDetailView.swift's
//    `vehicleBreakdownSection`), matching the Figma reference where the
//    heading sits outside the card.
//

import SwiftUI

struct VehicleBreakdownView: View {

    let vehicle: VehicleTrafficResponse

    /// Per-vehicle-type colors are still computed here (kept from the
    /// real-data implementation) in case other UI — charts, legends,
    /// etc. — wants them later. The current row layout intentionally
    /// uses a uniform cyan icon color per the Figma reference instead.
    private var vehicleItems: [VehicleItem] {
        [
            VehicleItem(
                name: "Mobil",
                count: vehicle.volumeKendaraan.mobil,
                systemImage: "car.fill",
                color: .green
            ),
            VehicleItem(
                name: "Motor",
                count: vehicle.volumeKendaraan.motor,
                systemImage: "motorcycle.fill",
                color: .purple
            ),
            VehicleItem(
                name: "Bus",
                count: vehicle.volumeKendaraan.bus,
                systemImage: "bus.fill",
                color: .blue
            ),
            VehicleItem(
                name: "Truk",
                count: vehicle.volumeKendaraan.truk,
                systemImage: "truck.box.fill",
                color: .orange
            )
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {

            ForEach(vehicleItems) { item in

                HStack(spacing: 8) {

                    Image(systemName: item.systemImage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.cyan)
                        .frame(width: 16)

                    Text(item.name)
                        .font(.subheadline)
                        .foregroundStyle(.primary)

                    Spacer(minLength: 8)

                    Text("\(item.count)")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
                .frame(minHeight: 24)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    "\(item.name): \(item.count) kendaraan per jam"
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
//
// NOTE: VehicleTrafficResponse isn't included in the files sent so far,
// so this preview uses a placeholder initializer based on the property
// path referenced above (vehicle.volumeKendaraan.{mobil,motor,bus,truk}).
// Adjust to match your actual model definition if it differs.

//#if DEBUG
//#Preview {
//    VehicleBreakdownView(
//        vehicle: .init(
//            volumeKendaraan: .init(
//                mobil: 200,
//                motor: 900,
//                bus: 18,
//                truk: 6
//            )
//        )
//    )
//    .padding()
//    .background(
//        Color(.systemGroupedBackground)
//    )
//}
//#endif
