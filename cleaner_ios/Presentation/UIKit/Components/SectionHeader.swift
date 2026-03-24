import SwiftUI

// MARK: - SectionHeader
/// Reusable title + subtitle text block
///
/// Usage:
/// ```swift
/// SectionHeader(
///     title: "Smart recommendations",
///     subtitle: "Pick the options you'd like us to use to free up space on your iPhone"
/// )
/// ```

struct SectionHeader: View {

    let title: String
    let subtitle: String?

    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppFonts.sectionHeaderTitle)
                .foregroundColor(AppColors.sectionHeaderTitle)
                .tracking(-0.28)
                .lineSpacing(30 - 28)

            if let subtitle {
                Text(subtitle)
                    .font(AppFonts.sectionHeaderSubtitle)
                    .foregroundColor(AppColors.sectionHeaderSubtitle)
                    .lineSpacing(18 - 14)
            }
        }
        .frame(maxWidth: 340, alignment: .leading)
    }
}

#Preview {
    ZStack {
        Color(red: 0.847, green: 0.831, blue: 0.929).ignoresSafeArea()

        VStack(alignment: .leading, spacing: 40) {
            SectionHeader(
                title: "Smart recommendations",
                subtitle: "Pick the options you'd like us to use to free up space on your iPhone"
            )

            SectionHeader(
                title: "Files you can remove",
                subtitle: "Review suggested files before removing them from your device"
            )
        }
        .padding(.horizontal, 28)
    }
}
