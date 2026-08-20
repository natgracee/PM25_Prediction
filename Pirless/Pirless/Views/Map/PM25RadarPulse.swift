import SwiftUI

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

                // MARK: - Radar Pulse

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

                // MARK: - Center Glow

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
