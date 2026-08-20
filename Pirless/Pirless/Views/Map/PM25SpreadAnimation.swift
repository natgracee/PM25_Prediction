//
//  PM25SpreadAnimation.swift
//  Pirless
//
//  Created by M. TAQWA ADDARI on 18/08/26.
//

import SwiftUI

struct PM25SpreadAnimation: View {

    let directionDegrees: Double
    let visibility: Double

    var body: some View {
        TimelineView(.animation) { context in

            ZStack {
                ForEach(0..<5, id: \.self) { index in
                    spreadParticle(
                        index: index,
                        time: context.date.timeIntervalSinceReferenceDate
                    )
                }
            }
            .frame(
                width: 20,
                height: 20
            )
            .allowsHitTesting(false)
        }
    }

    // MARK: - Particle

    private func spreadParticle(
        index: Int,
        time: TimeInterval
    ) -> some View {

        let progress = particleProgress(
            index: index,
            time: time
        )

        let distance = progress * 110

        let angle =
            directionDegrees * .pi / 180

        let x =
            sin(angle) * distance

        let y =
            -cos(angle) * distance

        let sideOffset =
            sin(
                progress * .pi * 2
                + Double(index)
            ) * 10

        let opacity =
            max(
                0.01,
                0.30 * (1 - progress) * visibility
            )

        return Circle()
            .fill(
                Color.orange.opacity(opacity)
            )
            .frame(
                width: particleSize(index),
                height: particleSize(index)
            )
            .offset(
                x: x + sideOffset,
                y: y
            )
    }

    // MARK: - Progress

    private func particleProgress(
        index: Int,
        time: TimeInterval
    ) -> CGFloat {

        let speed = 0.35

        let offset =
            Double(index) * 0.20

        let value =
            (time * speed + offset)
                .truncatingRemainder(
                    dividingBy: 1
                )

        return CGFloat(value)
    }

    // MARK: - Particle Size

    private func particleSize(
        _ index: Int
    ) -> CGFloat {

        switch index {
        case 0:
            return 7

        case 1:
            return 6

        case 2:
            return 8

        case 3:
            return 5

        default:
            return 6
        }
    }
}
