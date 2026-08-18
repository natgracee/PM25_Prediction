//
//  PM25LegendView.swift
//  Pirless
//
//  Created by M. TAQWA ADDARI on 17/08/26.
//

import SwiftUI

struct PM25LegendView: View {

    let onDismiss: () -> Void

    var body: some View {
        Button {
            onDismiss()
        } label: {
            VStack(alignment: .leading, spacing: 8) {

                Text("PM2.5")
                    .font(.headline)

                legendRow(
                    symbol: "🔴",
                    range: "> 55",
                    description: "Unhealthy"
                )

                legendRow(
                    symbol: "🟡",
                    range: "36–55",
                    description: "Moderate"
                )

                legendRow(
                    symbol: "🟢",
                    range: "0–35",
                    description: "Good"
                )
            }
            .padding(14)
            .background(
                .regularMaterial,
                in: RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .accessibilityLabel("Informasi PM2.5")
        .accessibilityHint("Ketuk untuk menutup")
    }

    private func legendRow(
        symbol: String,
        range: String,
        description: String
    ) -> some View {
        HStack(spacing: 8) {
            Text(symbol)

            Text(range)
                .fontWeight(.semibold)

            Text(description)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }
}

#Preview {
    PM25LegendView {
        print("Dismiss")
    }
}
