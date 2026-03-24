import SwiftUI

/// Simple progress bar line
/// Usage:
/// ```swift
/// ProgressBar(progress: 0.5)
/// ```
public struct ProgressBar: View {
    public var progress: Double // 0...1
    public var fillColor: Color
    private var clampedProgress: Double { min(max(progress, 0), 1) }

    public init(progress: Double, fillColor: Color? = nil) {
        self.progress = progress
        self.fillColor = fillColor ?? AppColors.progressBarFillGreen
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColors.progressBarTrack)
                    .frame(height: 5)
                Capsule()
                    .fill(fillColor)
                    .frame(width: geo.size.width * clampedProgress, height: 5)
            }
        }
        .frame(height: 5)
    }
}

#Preview {
    VStack(spacing: 24) {
        ProgressBar(progress: 11/28, fillColor: .green)
        ProgressBar(progress: 0.5, fillColor: .blue)
        ProgressBar(progress: 90/100)
    }
    .padding()
    .background(Color.black)
}
