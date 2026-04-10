import SwiftUI

struct SmartCleanupBrowse: View {
    @Environment(\.photoLibrary) var photoLibrary
    var namespace: Namespace.ID

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                SectionHeader(
                    title: "Files you can remove",
                    subtitle: "Review suggested files before removing them from your device"
                )

                ExpandableGroup(title: "Duplicates", subTitle: "\(photoLibrary?.duplicatesGroups.count ?? 0) groups", badgeText: "+ 100 GB") {
                    ForEach(photoLibrary?.duplicatesGroups ?? [], id: \.id) { group in
                        PhotoGridPreview(photos: group.photos, namespace: namespace)
                    }
                }
                .padding(.top, 30)

                ExpandableGroup(title: "Large files", subTitle: "6 groups", badgeText: "+ 100 GB") {
                    Text("Large files")
                }
                .padding(.top, 20)
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            AppColors.background.ignoresSafeArea()
        }
        .navigationTitle("Smart cleanup")
        .navigationBarTitleDisplayMode(.inline)
    }
}

