import SwiftUI

// MARK: - Reusable progress bar with text and values
/// Usage:
/// ```swift
/// ProgressBarWithText(
///     label: "You will recover",
///     currentValue: 54,
///     totalValue: 58,
///     unit: "GB",
///     progress: 54.0 / 58.0
/// )
/// ```

public struct ProgressBarWithText: View {
    let label: String
    let currentValue: Double
    let totalValue: Double
    var unit: String = "GB"
    let progress: Double

    private func formatValue(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(v))
            : String(format: "%.1f", v)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(label)
                    .font(AppFonts.progressBarLabel)
                    .foregroundColor(AppColors.progressBarText)
                    .tracking(-0.2)
                Spacer()
                HStack(spacing: 0) {
                    Text("\(formatValue(currentValue)) \(unit) ")
                        .font(AppFonts.progressBarLabel)
                        .foregroundColor(AppColors.progressBarText)
                        .tracking(-0.2)
                    Text("/ \(formatValue(totalValue)) \(unit)")
                        .font(AppFonts.progressBarLabel)
                        .foregroundColor(AppColors.progressBarTrackText)
                        .tracking(-0.2)
                }
            }
            ProgressBar(progress: progress)
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.42, green: 0.35, blue: 0.82),
                Color(red: 0.60, green: 0.55, blue: 0.90)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 32) {
            ProgressBarWithText(
                label: "You will recover",
                currentValue: 54,
                totalValue: 58,
                unit: "GB",
                progress: 54.0 / 58.0
            )
            ProgressBarWithText(
                label: "Photos",
                currentValue: 12,
                totalValue: 20,
                unit: "GB",
                progress: 12.0 / 20.0
            )
            ProgressBarWithText(
                label: "Videos",
                currentValue: 1,
                totalValue: 10,
                unit: "GB",
                progress: 0.1
            )
        }
        .padding(.horizontal, 24)
    }
}
