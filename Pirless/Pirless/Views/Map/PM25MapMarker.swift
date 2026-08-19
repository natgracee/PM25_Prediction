//
//  PM25MapMarker.swift
//  Pirless
//
//  Created by M. TAQWA ADDARI on 17/08/26.
//

import SwiftUI

struct PM25MapMarker: View {
    let value: Double

    private var backgroundColor: Color {
        switch value {
        case 0...35:
            .green
        case 36...55:
            .yellow
        default:
            .red
        }
    }

    var body: some View {
        Text(formattedValue)
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(backgroundColor, in: Circle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                "PM2.5 \(formattedValue) mikrogram per meter kubik"
            )
    }

    private var formattedValue: String {
        value.formatted(.number.precision(.fractionLength(0)))
    }
}

#Preview {
    VStack(spacing: 16) {
        PM25MapMarker(value: 61)
        PM25MapMarker(value: 38)
        PM25MapMarker(value: 25)
    }
}

