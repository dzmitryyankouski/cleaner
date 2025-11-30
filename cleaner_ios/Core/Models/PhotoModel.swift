import SwiftData
import Photos

@Model
final class PhotoModel {
    @Attribute(.unique) var id: String
    @Relationship(deleteRule: .nullify)
    var groups: [PhotoGroupModel] = []

    var embedding: [Float]?
    var creationDate: Date?
    var fileSize: Int64?
    var isScreenshot: Bool = false
    var isLivePhoto: Bool = false
    var isModified: Bool = false
    var isFavorite: Bool = false
    var fullScreenFrameWidth: Double = 0
    var fullScreenFrameHeight: Double = 0
    
    private static var assetCache: [String: PHAsset] = [:]
    private static let cacheQueue = DispatchQueue(label: "com.cleaner.assetCache", attributes: .concurrent)
    
    init(asset: PHAsset) {
        self.id = asset.localIdentifier
        self.creationDate = asset.creationDate
        self.isScreenshot = asset.mediaSubtypes.contains(.photoScreenshot)
        self.isLivePhoto = asset.mediaSubtypes.contains(.photoLive)
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
