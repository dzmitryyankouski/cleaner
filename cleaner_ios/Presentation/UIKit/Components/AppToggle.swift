import SwiftUI

// MARK: - AppToggle
/// Custom ToggleStyle for pill-shaped toggle
struct PillToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        let trackWidth: CGFloat  = 64
        let trackHeight: CGFloat = 28
        let thumbWidth: CGFloat  = 39
        let thumbHeight: CGFloat = 24
        let padding: CGFloat     = 2
        let thumbOffset: CGFloat = configuration.isOn ? (trackWidth / 2 - thumbWidth / 2 - padding) : -(trackWidth / 2 - thumbWidth / 2 - padding)

        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                configuration.isOn.toggle()
            }
        }) {
            ZStack(alignment: .center) {
                Capsule()
                    .fill(configuration.isOn ? AppColors.toggleActiveBackground : AppColors.toggleInactiveBackground)
                    .frame(width: trackWidth, height: trackHeight)
                RoundedRectangle(cornerRadius: 100)
                    .fill(AppColors.toggleThumb)
                    .frame(width: thumbWidth, height: thumbHeight)
                    .offset(x: thumbOffset)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Toggle")
        .accessibilityValue(configuration.isOn ? "On" : "Off")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Reusable pill-shaped toggle (using Toggle with custom style)
struct AppToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Toggle("", isOn: $isOn)
            .toggleStyle(PillToggleStyle())
            .labelsHidden()
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
