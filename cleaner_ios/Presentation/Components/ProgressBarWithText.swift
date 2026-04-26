import SwiftUI

public struct ProgressBarWithText<Content: View>: View {
    let label: String
    let current: Double
    let total: Double
    let content: Content

    private var unit: String = "GB"

    public init(
        label: String,
        current: Double,
        total: Double,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.current = current
        self.total = total
        self.content = content()
    }

    private func formatValue(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(v))
            : String(format: "%.1f", v)
    }

    private var fillProgress: Double {
        total > 0 ? min(current / total, 1) : 0
    }

    var backgroundGradient: LinearGradient {
        let degrees = 49.0
        let radians = (degrees - 90) * Double.pi / 180
        let x = cos(radians)
        let y = sin(radians)
        let start = UnitPoint(x: 0.5 - 0.5 * x, y: 0.5 - 0.5 * y)
        let end = UnitPoint(x: 0.5 + 0.5 * x, y: 0.5 + 0.5 * y)
        let span = 98.66 - (-14.78)
        let mid = (41.94 - (-14.78)) / span
        return LinearGradient(
            stops: [
                .init(color: Color(red: 128 / 255, green: 152 / 255, blue: 247 / 255), location: 0),
                .init(color: Color(red: 182 / 255, green: 183 / 255, blue: 216 / 255), location: mid),
                .init(color: Color(red: 118 / 255, green: 115 / 255, blue: 213 / 255), location: 1),
            ],
            startPoint: start,
            endPoint: end
        )
    }

    public var body: some View {
        VStack(spacing: 30) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(label)
                        .font(AppFonts.geologica(size: 20, wght: 500))
                        .foregroundColor(AppColors.progressBarText)
                        .tracking(-0.2)
                    Spacer()
                    HStack(spacing: 0) {
                        Text("\(formatValue(current)) \(unit) ")
                            .font(AppFonts.geologica(size: 20, wght: 500))
                            .foregroundColor(AppColors.progressBarText)
                            .tracking(-0.2)
                            .contentTransition(.numericText())
                    }
                    .animation(.easeInOut(duration: 0.35), value: current)
                }
                ProgressBar(progress: fillProgress, fillColor: .white)
                    .animation(.easeInOut(duration: 0.35), value: fillProgress)
            }

            content
        }
        .padding(24)
        .background(backgroundGradient)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    }
}
