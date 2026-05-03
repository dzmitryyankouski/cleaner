import SwiftUI

struct SmartCleanupBrowse: View {
    @Environment(\.photoLibrary) var photoLibrary
    @Environment(\.mediaLibrary) var mediaLibrary
    var namespace: Namespace.ID

    @State private var selectedLargeFile: MediaItem?

    var body: some View {
        let duplicateGroups = photoLibrary?.duplicatesGroups ?? []
        let largeFiles = mediaLibrary?.largeFiles ?? []
        let displayedLargeFiles = Array(largeFiles.prefix(4))

        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                SectionHeader(
                    title: "Files you can remove",
                    subtitle: "Review suggested files before removing them from your device"
                )

                ExpandableGroup(title: "Duplicates", subTitle: "\(duplicateGroups.count) groups", badgeText: "+ 100 GB") { isExpanded in
                    if let firstGroup = duplicateGroups.first {
                        PhotoGridPreview(photos: firstGroup.photos, namespace: namespace)
                    }

                    if isExpanded {
                        ForEach(Array(duplicateGroups.dropFirst()), id: \.id) { group in
                            PhotoGridPreview(photos: group.photos, namespace: namespace)
                        }
                    }
                }
                .padding(.top, 30)

                ExpandableGroup(title: "Large files", subTitle: "\(largeFiles.count) files", badgeText: "+ 100 GB") { isExpanded in
                    let currentLargeFiles = isExpanded ? largeFiles : displayedLargeFiles

                    if !currentLargeFiles.isEmpty {
                        MediaGrid(
                            items: currentLargeFiles,
                            selectedItem: $selectedLargeFile,
                            columns: 4,
                            namespace: namespace
                        )
                    }
                }
                .padding(.top, 20)
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .fullScreenCover(item: $selectedLargeFile) { item in
            MediaDetailView(items: largeFiles, currentItem: item, namespace: namespace)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            AppColors.background.ignoresSafeArea()
        }
        .navigationTitle("Smart cleanup")
        .navigationBarTitleDisplayMode(.inline)
    }
}

