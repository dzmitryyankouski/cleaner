import SwiftUI

/// Simple progress bar line
/// Usage:
/// ```swift
/// ProgressBar(progress: 0.5)
/// ```
public struct ProgressBar: View {
    public var progress: Double // 0...1
    private var clampedProgress: Double { min(max(progress, 0), 1) }

    public init(progress: Double) {
        self.progress = progress
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColors.progressBarTrack)
                    .frame(height: 5)
                Capsule()
                    .fill(AppColors.progressBarFill)
                    .frame(width: geo.size.width * clampedProgress, height: 5)
            }
        }
        .frame(height: 5)
    }
}

#Preview {
    VStack(spacing: 24) {
        ProgressBar(progress: 11/28)
        ProgressBar(progress: 0.5)
        ProgressBar(progress: 90/100)
    }
    .padding()
    .background(Color.black)
}
