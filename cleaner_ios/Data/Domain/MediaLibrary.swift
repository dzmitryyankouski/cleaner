import Foundation
import Observation

@Observable
final class MediaLibrary {
    static let largeFileThresholdBytes: Int64 = 200 * 1024 * 1024
    static let shortVideoMaxDurationSeconds: TimeInterval = 6

    private let photoLibrary: PhotoLibrary
    private let videoLibrary: VideoLibrary

    var totalGB: Double = 0
    var usedGB: Double = 0

    var largeFilesSelected: Bool = false
    var duplicatesSelected: Bool = false
    var blurryPhotosSelected: Bool = false
    var shortVideosSelected: Bool = false
    var optimizeLivePhotosSelected: Bool = false

    var selectedStorageBytes: Int64 = 0
    var recoverableStorageBytes: Int64 = 0

    init(photoLibrary: PhotoLibrary, videoLibrary: VideoLibrary) {
        self.photoLibrary = photoLibrary
        self.videoLibrary = videoLibrary

        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()) {
            let total = attrs[.systemSize] as? NSNumber
            let free = attrs[.systemFreeSize] as? NSNumber
            let usedBytes = (total?.uint64Value ?? 0) - (free?.uint64Value ?? 0)

            usedGB = Double(usedBytes) / 1_000_000_000
            totalGB = Double(total?.uint64Value ?? 0) / 1_000_000_000
        }

        refreshSelectedStorage()
    }

    var items: [MediaItem] {
        let mixed = photoLibrary.photos.map { MediaItem.photo($0) }
            + videoLibrary.videos.map { MediaItem.video($0) }

        return mixed.sorted {
            ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast)
        }
    }

    var selectedItems: [MediaItem] {
        photoLibrary.selectedPhotos.values.map { MediaItem.photo($0) }
            + videoLibrary.selectedVideos.values.map { MediaItem.video($0) }
    }

    var selectedStorageGB: Double {
        Double(selectedStorageBytes) / 1_000_000_000
    }

    var recoverableStorageGB: Double {
        Double(recoverableStorageBytes) / 1_000_000_000
    }

    func refreshSelectedStorage() {
        let photoBytes = photoLibrary.selectedPhotos.values.reduce(Int64(0)) { $0 + ($1.fileSize ?? 0) }
        let videoBytes = videoLibrary.selectedVideos.values.reduce(Int64(0)) { $0 + ($1.fileSize ?? 0) }
        let livePhotoBytes = photoLibrary.selectedForLiveOptimization.values.reduce(Int64(0)) {
            $0 + ($1.livePhotoVideoFileSize ?? 0)
        }

        selectedStorageBytes = photoBytes + videoBytes + livePhotoBytes
    }

    var hasSelection: Bool {
        !selectedItems.isEmpty
    }

    func isSelected(_ item: MediaItem) -> Bool {
        switch item {
        case .photo(let photo):
            return photoLibrary.selectedPhotos[photo.id] != nil
        case .video(let video):
            return videoLibrary.selectedVideos[video.id] != nil
        }
    }

    func select(_ item: MediaItem) {
        switch item {
        case .photo(let photo):
            photoLibrary.selectedPhotos[photo.id] = photo
        case .video(let video):
            videoLibrary.selectedVideos[video.id] = video
        }
    }

    func deselect(_ item: MediaItem) {
        switch item {
        case .photo(let photo):
            photoLibrary.selectedPhotos.removeValue(forKey: photo.id)
        case .video(let video):
            videoLibrary.selectedVideos.removeValue(forKey: video.id)
        }
    }

    func clearSelection() {
        photoLibrary.selectedPhotos.removeAll()
        videoLibrary.selectedVideos.removeAll()
        refreshSelectedStorage()
    }

    func reconcile() {
        for item in items {
            let shouldSelect =
                (largeFilesSelected && isLargeFile(item))
                || (duplicatesSelected && isInDuplicateGroups(item))
                || (blurryPhotosSelected && isBlurryPhoto(item))
                || (shortVideosSelected && isShortVideo(item))

            shouldSelect ? select(item) : deselect(item)

            if case .photo(let photo) = item {
                if optimizeLivePhotosSelected && !isSelected(item) && isLivePhoto(item) {
                    photoLibrary.selectedForLiveOptimization[photo.id] = photo
                } else {
                    photoLibrary.selectedForLiveOptimization.removeValue(forKey: photo.id)
                }
            }
        }

        refreshSelectedStorage()
    }

    func calculateRecoverableStorageBytes() {
        var total: Int64 = 0

        for item in items {
            if (isLargeFile(item) || isInDuplicateGroups(item) || isBlurryPhoto(item) || isShortVideo(item)) {
                total += item.fileSize ?? 0
            } else if (isLivePhoto(item)) {
                total += item.livePhotoVideoFileSize ?? 0
            }
        }

        recoverableStorageBytes = total
    }

    private func isLivePhoto(_ item: MediaItem) -> Bool {
        switch item {
        case .photo(let photo):
            return photo.isLivePhoto
        case .video:
            return false
        }
    }

    private func isBlurryPhoto(_ item: MediaItem) -> Bool {
        switch item {
        case .photo(let photo):
            return photo.isBlurry
        case .video:
            return false
        }
    }

    private func isInDuplicateGroups(_ item: MediaItem) -> Bool {
        switch item {
        case .photo(let photo):
            return photoLibrary.duplicatesGroups.contains { group in
                guard let index = group.photos.firstIndex(where: { $0.id == photo.id }) else { return false }
                return index > 0
            }
        case .video:
            return false
        }
    }

    private func isLargeFile(_ item: MediaItem) -> Bool {
        switch item {
        case .photo(let photo):
            return photo.fileSize ?? 0 > Self.largeFileThresholdBytes
        case .video(let video):
            return video.fileSize ?? 0 > Self.largeFileThresholdBytes
        }
    }

    private func isShortVideo(_ item: MediaItem) -> Bool {
        switch item {
        case .photo:
            return false
        case .video(let video):
            return video.duration > 0 && video.duration < Self.shortVideoMaxDurationSeconds
        }
    }

    func delete(_ items: [MediaItem]) async -> Result<Void, AssetError> {
        let photos = items.compactMap { item -> PhotoModel? in
            guard case .photo(let photo) = item else { return nil }
            return photo
        }
        let videos = items.compactMap { item -> VideoModel? in
            guard case .video(let video) = item else { return nil }
            return video
        }

        if !photos.isEmpty {
            let photoResult = await photoLibrary.delete(photos: photos)
            guard case .success = photoResult else {
                return .failure(.loadingFailed)
            }
        }

        if !videos.isEmpty {
            let videoResult = await videoLibrary.delete(videos: videos)
            guard case .success = videoResult else {
                return .failure(.loadingFailed)
            }
        }

        return .success(())
    }

    func deleteSelected() async -> Result<Void, AssetError> {
        await delete(selectedItems)
    }

    func search(query: String) async -> Result<[SearchResult<MediaItem>], SearchError> {
        async let photoResult = photoLibrary.search(query: query)
        async let videoResult = videoLibrary.search(query: query)

        let photos = await photoResult
        let videos = await videoResult

        var combined: [SearchResult<MediaItem>] = []

        if case .success(let photoResults) = photos {
            combined += photoResults.map { SearchResult(item: .photo($0.item), similarity: $0.similarity) }
        } else if case .failure(let error) = photos {
            return .failure(error)
        }

        if case .success(let videoResults) = videos {
            combined += videoResults.map { SearchResult(item: .video($0.item), similarity: $0.similarity) }
        } else if case .failure(let error) = videos {
            return .failure(error)
        }

        combined.sort { $0.similarity > $1.similarity }
        return .success(combined)
    }
}
