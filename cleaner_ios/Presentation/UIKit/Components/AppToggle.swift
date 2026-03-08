import SwiftUI

// MARK: - AppToggle
/// Reusable pill-shaped toggle
///
/// Usage:
/// ```swift
/// @State private var isOn = false
/// AppToggle(isOn: $isOn)
/// ```

struct AppToggle: View {

    @Binding var isOn: Bool

    private let trackWidth: CGFloat  = 64
    private let trackHeight: CGFloat = 28
    private let thumbWidth: CGFloat  = 39
    private let thumbHeight: CGFloat = 24
    private let padding: CGFloat     = 2

    private var thumbOffset: CGFloat {
        let base = trackWidth / 2 - thumbWidth / 2 - padding
        return isOn ? base : -base
    }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isOn.toggle()
            }
        } label: {
            ZStack {
                Capsule()
                    .fill(isOn ? AppColors.toggleActiveBackground : AppColors.toggleInactiveBackground)
                    .frame(width: trackWidth, height: trackHeight)

                RoundedRectangle(cornerRadius: 100)
                    .fill(AppColors.toggleThumb)
                    .frame(width: thumbWidth, height: thumbHeight)
                    .offset(x: thumbOffset)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var first = true
        @State private var second = false

        var body: some View {
            ZStack {
                Color.white.ignoresSafeArea()

                HStack(spacing: 24) {
                    AppToggle(isOn: $first)
                    AppToggle(isOn: $second)
                }
                .padding()
            }
        }
    }
    return PreviewWrapper()
}
