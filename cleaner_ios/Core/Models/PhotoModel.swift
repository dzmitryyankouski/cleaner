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

    static var similar: FetchDescriptor<PhotoModel> {
        FetchDescriptor(
            predicate: #Predicate<PhotoModel> { photo in
                photo.groups.contains { $0.type == "similar" }
            }
        )
    }

    static var duplicates: FetchDescriptor<PhotoModel> {
        FetchDescriptor(
            predicate: #Predicate<PhotoModel> { photo in
                photo.groups.contains { $0.type == "duplicates" }
            }
        )
    }

    static var withEmbedding: FetchDescriptor<PhotoModel> {
        FetchDescriptor(
            predicate: #Predicate<PhotoModel> { $0.embedding != nil }
        )
    }

    static var screenshots: FetchDescriptor<PhotoModel> {
        FetchDescriptor(
            predicate: #Predicate<PhotoModel> { $0.isScreenshot },
            sortBy: [SortDescriptor(\.creationDate, order: .reverse)]
        )
    }
}
