import SwiftUI

struct SmartCleanupBrowse: View {
    @Environment(\.photoLibrary) var photoLibrary
    @Environment(\.mediaLibrary) var mediaLibrary
    var namespace: Namespace.ID

    @State private var selectedDuplicatesBytes: Int64 = 0
    @State private var selectedLargeFilesBytes: Int64 = 0
    @State private var selectedBlurryPhotosBytes: Int64 = 0
    @State private var selectedShortVideosBytes: Int64 = 0
    @State private var selectedLargeFile: MediaItem?
    @State private var selectedBlurryPhoto: MediaItem?
    @State private var selectedShortVideo: MediaItem?

    var body: some View {
        let duplicateGroups = photoLibrary?.duplicatesGroups ?? []
        let duplicateBadgeText = "+ \(FileSize(bytes: selectedDuplicatesBytes).formatted)"
        let largeFilesBadgeText = "+ \(FileSize(bytes: selectedLargeFilesBytes).formatted)"
        let blurryPhotosBadgeText = "+ \(FileSize(bytes: selectedBlurryPhotosBytes).formatted)"
        let shortVideosBadgeText = "+ \(FileSize(bytes: selectedShortVideosBytes).formatted)"

        let showsDuplicates = mediaLibrary?.duplicatesSelected ?? false
        let showsLargeFiles = mediaLibrary?.largeFilesSelected ?? false
        let showsBlurryPhotos = mediaLibrary?.blurryPhotosSelected ?? false
        let showsShortVideos = mediaLibrary?.shortVideosSelected ?? false

        let largeFiles = mediaLibrary?.largeFiles ?? []
        let displayedLargeFiles = Array(largeFiles.prefix(4))
        
        let blurryPhotos = mediaLibrary?.blurryPhotos ?? []
        let displayedBlurryPhotos = Array(blurryPhotos.prefix(4))
        
        let shortVideos = mediaLibrary?.shortVideos ?? []
        let displayedShortVideos = Array(shortVideos.prefix(4))

        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                SectionHeader(
                    title: "Files you can remove",
                    subtitle: "Review suggested files before removing them from your device"
                )

                if showsDuplicates {
                    ExpandableGroup(title: "Duplicates", subTitle: "\(duplicateGroups.count) groups", badgeText: duplicateBadgeText) { isExpanded in
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
                }

                if showsLargeFiles {
                    ExpandableGroup(title: "Large files", subTitle: "\(largeFiles.count) files", badgeText: largeFilesBadgeText) { isExpanded in
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

                if showsBlurryPhotos {
                    ExpandableGroup(title: "Blurry photos", subTitle: "\(blurryPhotos.count) files", badgeText: blurryPhotosBadgeText) { isExpanded in
                        let currentBlurryPhotos = isExpanded ? blurryPhotos : displayedBlurryPhotos

                        if !currentBlurryPhotos.isEmpty {
                            MediaGrid(
                                items: currentBlurryPhotos,
                                selectedItem: $selectedBlurryPhoto,
                                columns: 4,
                                namespace: namespace
                            )
                        }
                    }
                    .padding(.top, 20)
                }

                if showsShortVideos {
                    ExpandableGroup(title: "Short videos", subTitle: "\(shortVideos.count) files", badgeText: shortVideosBadgeText) { isExpanded in
                        let currentShortVideos = isExpanded ? shortVideos : displayedShortVideos

                        if !currentShortVideos.isEmpty {
                            MediaGrid(
                                items: currentShortVideos,
                                selectedItem: $selectedShortVideo,
                                columns: 4,
                                namespace: namespace
                            )
                        }
                    }
                    .padding(.top, 20)
                }
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .fullScreenCover(item: $selectedLargeFile) { item in
            MediaDetailView(items: largeFiles, currentItem: item, namespace: namespace)
        }
        .fullScreenCover(item: $selectedBlurryPhoto) { item in
            MediaDetailView(items: blurryPhotos, currentItem: item, namespace: namespace)
        }
        .fullScreenCover(item: $selectedShortVideo) { item in
            MediaDetailView(items: shortVideos, currentItem: item, namespace: namespace)
        }
        .task {
            recalculateSelectedStorageForGroups()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            AppColors.background.ignoresSafeArea()
        }
        .navigationTitle("Smart cleanup")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func recalculateSelectedStorageForGroups() {
        let duplicateGroups = photoLibrary?.duplicatesGroups ?? []
        let largeFiles = mediaLibrary?.largeFiles ?? []
        let blurryPhotos = mediaLibrary?.blurryPhotos ?? []
        let shortVideos = mediaLibrary?.shortVideos ?? []

        var duplicatesBytes: Int64 = 0
        for group in duplicateGroups {
            for photo in group.photos where mediaLibrary?.isSelected(.photo(photo)) == true {
                duplicatesBytes += photo.fileSize ?? 0
            }
        }

        var largeFilesBytes: Int64 = 0
        for item in largeFiles {
            if mediaLibrary?.isSelected(item) == true {
                largeFilesBytes += item.fileSize ?? 0
            }
        }

        var blurryPhotosBytes: Int64 = 0
        for item in blurryPhotos {
            if mediaLibrary?.isSelected(item) == true {
                blurryPhotosBytes += item.fileSize ?? 0
            }
        }

        var shortVideosBytes: Int64 = 0
        for item in shortVideos {
            if mediaLibrary?.isSelected(item) == true {
                shortVideosBytes += item.fileSize ?? 0
            }
        }

        selectedDuplicatesBytes = duplicatesBytes
        selectedLargeFilesBytes = largeFilesBytes
        selectedBlurryPhotosBytes = blurryPhotosBytes
        selectedShortVideosBytes = shortVideosBytes
    }
}

