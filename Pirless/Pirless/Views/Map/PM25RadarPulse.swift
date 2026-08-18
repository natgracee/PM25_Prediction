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
import MapKit

struct PM25RadarPulse: MapContent {

    let coordinate: CLLocationCoordinate2D
    let color: Color
    let scale: CGFloat
    let visibility: Double

    @MapContentBuilder
    var body: some MapContent {

        Annotation(
            "",
            coordinate: coordinate
        ) {
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
            }
        }
    }
}
