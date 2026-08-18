//
//  PM25RadarPulse  .swift
//  Pirless
//
//  Created by M. TAQWA ADDARI on 18/08/26.
//

//
//  PM25RadarPulse.swift
//  Pirless
//

import SwiftUI

// NOTE: This used to be its own `MapContent` conformance that wrapped
// itself in a separate `Annotation` at the point's coordinate. That meant
// every PM2.5 point produced 3 separate MapKit annotation views stacked at
// the same coordinate (this, PM25SpreadAnimation, and the marker), which
// could make MapKit's own hit-testing/annotation-selection ambiguous even
// though this view was already `.allowsHitTesting(false)`. It is now a
// plain `View` that MapView composes into ONE shared `Annotation` per
// point, alongside PM25SpreadAnimation and the marker, in a single ZStack.
struct PM25RadarPulse: View {

    let color: Color
    let scale: CGFloat
    let visibility: Double

    var body: some View {
        TimelineView(.animation) { context in

            let time =
                context.date.timeIntervalSinceReferenceDate

            let progress =
                (time.truncatingRemainder(dividingBy: 2.0)) / 2.0

            let baseSize: CGFloat = 30 * scale

            let pulseSize =
                baseSize
                + (progress * 70 * scale)

            ZStack {

                // Radar pulse
                Circle()
                    .stroke(
                        color.opacity(
                            visibility
                            * 0.35
                            * (1 - progress)
                        ),
                        lineWidth: 2
                    )
                    .frame(
                        width: pulseSize,
                        height: pulseSize
                    )

                // Center glow
                Circle()
                    .fill(
                        color.opacity(
                            visibility * 0.12
                        )
                    )
                    .frame(
                        width: baseSize,
                        height: baseSize
                    )
            }
            .frame(
                width: 110 * scale,
                height: 110 * scale
            )
            .allowsHitTesting(false)
        }
    }
}
