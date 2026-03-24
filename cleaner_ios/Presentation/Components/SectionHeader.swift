import SwiftUI

struct SectionHeader: View {

    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppFonts.sectionHeaderTitle)
                .foregroundColor(AppColors.sectionHeaderTitle)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(AppFonts.sectionHeaderSubtitle)
                    .foregroundColor(AppColors.sectionHeaderSubtitle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
