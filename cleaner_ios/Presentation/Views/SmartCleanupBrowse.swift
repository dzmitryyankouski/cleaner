import SwiftUI

struct SmartCleanupBrowse: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(
                title: "Files you can remove",
                subtitle: "Review suggested files before removing them from your device"
            )
            
            ExpandableGroup(title: "Duplicates", subTitle: "6 groups", badgeText: "+ 100 GB") {
                Text("Large files")
            }
            .padding(.top, 30)

            ExpandableGroup(title: "Large files", subTitle: "6 groups", badgeText: "+ 100 GB") {
                Text("Large files")
            }
            .padding(.top, 20)

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

