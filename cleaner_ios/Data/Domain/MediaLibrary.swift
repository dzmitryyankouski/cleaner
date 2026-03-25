import Foundation
import Observation

@Observable
final class MediaLibrary {
    /// Порог «большого» файла (200 MiB), в байтах.
    static let largeFileThresholdBytes: Int64 = 200 * 1024 * 1024

    private let photoLibrary: PhotoLibrary
    private let videoLibrary: VideoLibrary

    var totalGB: Double = 0
    var usedGB: Double = 0

    var largeFilesSelected: Bool = false
    var duplicatesSelected: Bool = false
    var blurryPhotosSelected: Bool = false
    var oldFilesSelected: Bool = false
    var optimizeLivePhotosSelected: Bool = false

    /// Кэш суммы `fileSize` выбранных фото и видео; обновляется через `refreshSelectedStorage()`.
    var selectedStorageBytes: Int64 = 0

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
        photoLibrary.selectedPhotos.map { MediaItem.photo($0) }
            + videoLibrary.selectedVideos.map { MediaItem.video($0) }
    }

    var selectedStorageGB: Double {
        Double(selectedStorageBytes) / 1_000_000_000
    }

    func refreshSelectedStorage() {
        let photoBytes = photoLibrary.selectedPhotos.reduce(Int64(0)) { $0 + ($1.fileSize ?? 0) }
        let videoBytes = videoLibrary.selectedVideos.reduce(Int64(0)) { $0 + ($1.fileSize ?? 0) }
        selectedStorageBytes = photoBytes + videoBytes
    }

    var hasSelection: Bool {
        !selectedItems.isEmpty
    }

    func isSelected(_ item: MediaItem) -> Bool {
        switch item {
        case .photo(let photo):
            return photoLibrary.selectedPhotos.contains(photo)
        case .video(let video):
            return videoLibrary.selectedVideos.contains(video)
        }
    }

    func select(_ item: MediaItem) {
        switch item {
        case .photo(let photo):
            photoLibrary.selectedPhotos.append(photo)
        case .video(let video):
            videoLibrary.selectedVideos.append(video)
        }
    }

    func deselect(_ item: MediaItem) {
        switch item {
        case .photo(let photo):
            photoLibrary.selectedPhotos.removeAll { $0.id == photo.id }
        case .video(let video):
            videoLibrary.selectedVideos.removeAll { $0.id == video.id }
        }
    }

    func clearSelection() {
        photoLibrary.selectedPhotos.removeAll()
        videoLibrary.selectedVideos.removeAll()
        refreshSelectedStorage()
    }

    func reconcile(largeFiles: Bool, duplicates: Bool, blurryPhotos: Bool, oldFiles: Bool, optimizeLivePhotos: Bool) {
        for item in items {
            if (largeFiles && isLargeFile(item)) || (duplicates && isInDuplicateGroups(item)) || (oldFiles && isOldFile(item)) {
                if !isSelected(item) { select(item) }
            } else {
                deselect(item)
            }
        }

        refreshSelectedStorage()
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

    private func isOldFile(_ item: MediaItem) -> Bool {
        let threshold = Date().addingTimeInterval(-180 * 24 * 60 * 60)
        
        switch item {
        case .photo(let photo):
            guard let date = photo.creationDate else { return false }
            return date < threshold
        case .video(let video):
            guard let date = video.creationDate else { return false }
            return date < threshold
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
