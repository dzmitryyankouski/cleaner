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
            photoLibrary.select(photo: photo)
        case .video(let video):
            videoLibrary.select(video: video)
        }
        refreshSelectedStorage()
    }

    func clearSelection() {
        photoLibrary.selectedPhotos.removeAll()
        videoLibrary.selectedVideos.removeAll()
        refreshSelectedStorage()
    }

    /// Добавляет в выбор все фото и видео с известным размером больше `Self.largeFileThresholdBytes`, либо снимает такие элементы с выбора.
    func setLargeFilesSelection(_ selected: Bool) {
        if selected {
            for item in items {
                let bytes: Int64?
                switch item {
                case .photo(let photo): bytes = photo.fileSize
                case .video(let video): bytes = video.fileSize
                }
                guard let bytes, bytes > Self.largeFileThresholdBytes else { continue }

                switch item {
                case .photo(let photo):
                    if !photoLibrary.selectedPhotos.contains(where: { $0.id == photo.id }) {
                        photoLibrary.selectedPhotos.append(photo)
                    }
                case .video(let video):
                    if !videoLibrary.selectedVideos.contains(where: { $0.id == video.id }) {
                        videoLibrary.selectedVideos.append(video)
                    }
                }
            }
        } else {
            photoLibrary.selectedPhotos.removeAll { ($0.fileSize ?? 0) > Self.largeFileThresholdBytes }
            videoLibrary.selectedVideos.removeAll { ($0.fileSize ?? 0) > Self.largeFileThresholdBytes }
        }
        refreshSelectedStorage()
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
