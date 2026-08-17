import SwiftUI

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

    var body: some View {
        VStack(spacing: 0) {

            ZStack {

                // MARK: - Half Circle

                HalfCircleArc()
                    .stroke(
                        gaugeColor,
                        style: StrokeStyle(
                            lineWidth: 8,
                            lineCap: .round
                        )
                    )
                    .frame(
                        width: 240,
                        height: 120
                    )

                // MARK: - PM2.5 Value

                VStack(spacing: 0) {

                    Text(
                        value.formatted(
                            .number.precision(
                                .fractionLength(0)
                            )
                        )
                    )
                    .font(
                        .system(
                            size: 50,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(.primary)

                    Text("µg/m³")
                        .font(.system(size: 13))
                        .foregroundStyle(.primary)

                    Text(statusText)
                        .font(
                            .system(
                                size: 13,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(gaugeColor)
                        .padding(.top, 10)
                }
                .offset(y: 8)
            }
            .frame(
                width: 260,
                height: 150
            )
        }
    }
}

// MARK: - Half Circle Shape

private struct HalfCircleArc: Shape {

    func path(in rect: CGRect) -> Path {

        var path = Path()

        let center = CGPoint(
            x: rect.midX,
            y: rect.maxY
        )

        let radius = min(
            rect.width / 2,
            rect.height
        )

        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(360),
            clockwise: false
        )

        return path
    }
}

#Preview {
    VStack(spacing: 30) {
        PM25GaugeView(value: 25)
        PM25GaugeView(value: 45)
        PM25GaugeView(value: 61)
    }
}
