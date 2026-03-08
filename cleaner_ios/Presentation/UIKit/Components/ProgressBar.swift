import SwiftUI

// MARK: - Reusable progress bar
///
/// Usage:
/// ```swift
/// ProgressBar(
///     label: "You will recover",
///     currentValue: 54,
///     totalValue: 58,
///     unit: "GB",
///     progress: 54.0 / 58.0
/// )
/// ```

struct ProgressBar: View {

    let label: String
    let currentValue: Double
    let totalValue: Double
    var unit: String = "GB"
    let progress: Double

    private var clampedProgress: Double { min(max(progress, 0), 1) }

    private func formatValue(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(v))
            : String(format: "%.1f", v)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(label)
                    .font(AppFonts.progressBarLabel)
                    .foregroundColor(AppColors.progressBarText)
                    .tracking(-0.2) // -0.01em of 20pt

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

            // Track + fill
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.progressBarTrack)
                        .frame(height: 5)

                    // Fill
                    Capsule()
                        .fill(AppColors.progressBarFill)
                        .frame(width: geo.size.width * clampedProgress, height: 5)
                }
            }
            .frame(height: 5)
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
            ProgressBar(
                label: "You will recover",
                currentValue: 54,
                totalValue: 58,
                unit: "GB",
                progress: 54.0 / 58.0
            )

            ProgressBar(
                label: "Photos",
                currentValue: 12,
                totalValue: 20,
                unit: "GB",
                progress: 12.0 / 20.0
            )

            ProgressBar(
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
