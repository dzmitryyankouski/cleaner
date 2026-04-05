import SwiftUI

struct SmartCleanupBrowse: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(
                title: "Files you can remove",
                subtitle: "Review suggested files before removing them from your device"
            )
            Spacer(minLength: 0)
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            AppColors.background.ignoresSafeArea()
        }
        .navigationTitle("Smart cleanup")
        .navigationBarTitleDisplayMode(.inline)
    }
}
