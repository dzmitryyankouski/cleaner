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
            case .primary:           return AppColors.buttonPrimaryBackground
            case .secondary:         return AppColors.buttonSecondaryBackground
            case .custom(let color): return color
            }
        }

        var foregroundColor: Color {
            switch self {
            case .primary:           return AppColors.buttonPrimaryText
            case .secondary:         return AppColors.buttonSecondaryText
            case .custom:            return .white
            }
        }
    }

    let title: String
    let style: Style
    let icon: String?        // SF Symbol name; nil = text-only button
    let customIcon: AnyView? // Custom SwiftUI view used as icon
    let action: () -> Void

    // Standard init with optional SF Symbol icon
    init(
        title: String,
        style: Style = .primary,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.icon = icon
        self.customIcon = nil
        self.action = action
    }

    // Init with a custom icon view
    init<Icon: View>(
        title: String,
        style: Style = .primary,
        action: @escaping () -> Void,
        @ViewBuilder iconView: () -> Icon
    ) {
        self.title = title
        self.style = style
        self.icon = nil
        self.customIcon = AnyView(iconView())
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))

                if let customIcon {
                    customIcon
                } else if let icon {
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
