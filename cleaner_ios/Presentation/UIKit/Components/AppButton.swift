import SwiftUI

// MARK: - AppButton
/// Reusable pill-shaped button
///
/// Usage examples: under the #Preview

struct AppButton: View {

    enum Style {
        case primary
        case secondary
        case custom(Color)

        var backgroundColor: Color {
            switch self {
            case .primary:           return AppColors.primary
            case .secondary:         return AppColors.secondary
            case .custom(let color): return color
            }
        }

        var foregroundColor: Color {
            switch self {
            case .primary:           return .white
            case .secondary:         return .white
            case .custom:            return .white
            }
        }
    }

    let title: String
    let style: Style
    let icon: String?        // SF Symbol name; nil = text-only button
    let action: () -> Void

    init(
        title: String,
        style: Style = .primary,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))

                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(style.foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: AppSizes.buttonHeight)
            .background(style.backgroundColor)
            .clipShape(Capsule())
        }
    }
}

#Preview {
    ZStack {
        Color(red: 0.6, green: 0.65, blue: 0.95)
            .ignoresSafeArea()

        VStack(spacing: 12) {
            AppButton(title: "Recover 58 GB", icon: "plus.circle") { }
                .padding(.horizontal, 16)

            AppButton(title: "See full report", style: .secondary) { }
                .padding(.horizontal, 16)

            AppButton(title: "See recommendations", style: .primary, icon: "eye") { }
                .padding(.horizontal, 16)

            AppButton(title: "Recover more", style: .primary, icon: "plus.circle") { }
                .padding(.horizontal, 16)

            AppButton(title: "Finish cleaning", style: .secondary) { }
                .padding(.horizontal, 16)
        }
        .padding(.vertical)
    }
}
