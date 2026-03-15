import Foundation
import Observation

@Observable
final class MediaLibrary {
    private let photoLibrary: PhotoLibrary
    private let videoLibrary: VideoLibrary

    init(photoLibrary: PhotoLibrary, videoLibrary: VideoLibrary) {
        self.photoLibrary = photoLibrary
        self.videoLibrary = videoLibrary
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
    }

    func clearSelection() {
        photoLibrary.selectedPhotos.removeAll()
        videoLibrary.selectedVideos.removeAll()
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
