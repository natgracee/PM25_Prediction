//
//  PM25GaugeView.swift
//  Pirless
//

import SwiftUI

/// Big PM2.5 readout used on the Detail screen.
///
/// NOTE: The previous implementation drew a half-circle arc gauge around
/// the value. The Figma reference for this screen has no arc/ring at all —
/// just the large number, unit, and status label — so the arc was removed
/// to match the design.
struct PM25GaugeView: View {

    let value: Double

    // MARK: - PM2.5 Color

    private var gaugeColor: Color {
        switch value {
        case 0...35:
            return .green

        case 36...55:
            return .yellow

        default:
            return .red
        }
    }

    // MARK: - Status

    private var statusText: String {
        switch value {
        case 0...35:
            return "GOOD"

        case 36...55:
            return "MODERATE"

        default:
            return "UNHEALTHY"
        }
    }

    private var formattedValue: String {
        value.formatted(
            .number.precision(.fractionLength(0))
        )
    }

    var body: some View {
        VStack(spacing: 4) {

            Text(formattedValue)
                .font(.system(size: 50, weight: .heavy))
                .foregroundStyle(.primary)

            Text("µg/m³")
                .font(.subheadline)
                .foregroundStyle(.primary)

            Text(statusText)
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(gaugeColor)
                .padding(.top, 4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "PM2.5 \(formattedValue) mikrogram per meter kubik, status \(statusText)"
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        PM25GaugeView(value: 25)
        PM25GaugeView(value: 45)
        PM25GaugeView(value: 61)
    }
}
