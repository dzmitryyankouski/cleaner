import SwiftUI

struct AppToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Toggle("", isOn: $isOn)
            .labelsHidden()
            .tint(AppColors.toggleActiveBackground)
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
