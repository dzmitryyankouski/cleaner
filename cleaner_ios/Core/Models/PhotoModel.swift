import SwiftData
import Photos
import UIKit

@Model
final class PhotoModel: Identifiable {
    @Attribute(.unique) var id: String
    @Relationship(deleteRule: .nullify)
    var groups: [PhotoGroupModel] = []

    var embedding: [Float]?
    var creationDate: Date?
    var fileSize: Int64?
    var livePhotoVideoFileSize: Int64?
    var isScreenshot: Bool = false
    var isLivePhoto: Bool = false
    var isModified: Bool = false
    var isFavorite: Bool = false
    var isCompressed: Bool = false
    var isBlurry: Bool = false
    
    // MARK: - Transient (not saved to database)
    @Transient var image: UIImage?
    @Transient var quality: PhotoQuality?
    @Transient var isLoading: Bool = false
    
    // MARK: - Static
    private static var assetCache: [String: PHAsset] = [:]
    private static let cacheQueue = DispatchQueue(label: "com.cleaner.assetCache", attributes: .concurrent)
    private static let imageManager = PHCachingImageManager()
    
    init(asset: PHAsset) {
        self.id = asset.localIdentifier
        self.creationDate = asset.creationDate
        self.isScreenshot = asset.mediaSubtypes.contains(.photoScreenshot)
        self.isLivePhoto = asset.mediaSubtypes.contains(.photoLive)
    }
    
    // MARK: - Image Loading
    
    @MainActor
    func loadImage(quality: PhotoQuality) async -> UIImage? {
        if let cached = image, let currentQuality = self.quality {
            if currentQuality.level >= quality.level {
                return cached
            }
        }
        
        if isLoading {
            return image
        }
        
        isLoading = true
        
        let photoId = self.id
        
        let loadedImage: UIImage? = await withCheckedContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                let assets = PHAsset.fetchAssets(withLocalIdentifiers: [photoId], options: nil)
                guard let asset = assets.firstObject else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let options = PHImageRequestOptions()
                options.isSynchronous = false
                options.isNetworkAccessAllowed = true
                
                let targetSize: CGSize
                switch quality {
                case .low:
                    options.resizeMode = .fast
                    options.deliveryMode = .fastFormat
                    targetSize = CGSize(width: 150, height: 200)
                case .medium:
                    options.resizeMode = .exact
                    options.deliveryMode = .opportunistic
                    targetSize = CGSize(width: 300, height: 400)
                case .high:
                    options.resizeMode = .none
                    options.deliveryMode = .highQualityFormat
                    targetSize = PHImageManagerMaximumSize
                }
                
                Self.imageManager.requestImage(
                    for: asset,
                    targetSize: targetSize,
                    contentMode: .aspectFill,
                    options: options
                ) { image, info in
                    let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                    if !isDegraded {
                        continuation.resume(returning: image)
                    }
                }
            }
        }

        image = loadedImage
        self.quality = quality
        isLoading = false
        
        return image
    }

    static func apply(filter: Set<FilterPhoto>, sort: SortPhoto, type: String? = nil) -> FetchDescriptor<PhotoModel> {
        let sortDescriptors: [SortDescriptor<PhotoModel>]
        switch sort {
            case .date:
                sortDescriptors = [SortDescriptor(\.creationDate, order: .reverse)]
            case .size:
                sortDescriptors = [SortDescriptor(\.fileSize, order: .reverse)]
        }

        var filterPredicate = #Predicate<PhotoModel> { _ in true }
        var groupPredicate = #Predicate<PhotoModel> { _ in true }

        if !filter.isEmpty {
            let hasScreenshots = filter.contains(.screenshots)
            let hasLivePhotos = filter.contains(.livePhotos)
            let hasModified = filter.contains(.modified)
            let hasFavorites = filter.contains(.favorites)

            filterPredicate = #Predicate<PhotoModel> { photo in
                (hasScreenshots && photo.isScreenshot) ||
                (hasLivePhotos && photo.isLivePhoto) ||
                (hasModified && photo.isModified) ||
                (hasFavorites && photo.isFavorite)
            }
        }

        if let type = type {
            groupPredicate = #Predicate<PhotoModel> { photo in
                photo.groups.contains { $0.type == type }
            }
        }

        let predicate = #Predicate<PhotoModel> { photo in
            filterPredicate.evaluate(photo) && groupPredicate.evaluate(photo)
        }
        
        return FetchDescriptor(
            predicate: predicate,
            sortBy: sortDescriptors
        )
    }
}
