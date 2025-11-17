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
    var fullScreenFrameWidth: Double = 0
    var fullScreenFrameHeight: Double = 0
    
    private static var assetCache: [String: PHAsset] = [:]
    private static let cacheQueue = DispatchQueue(label: "com.cleaner.assetCache", attributes: .concurrent)
    
    init(asset: PHAsset) {
        self.id = asset.localIdentifier
        self.creationDate = asset.creationDate
        
        let resources = PHAssetResource.assetResources(for: asset)
        
        if let resource = resources.first, let size = resource.value(forKey: "fileSize") as? Int64, size > 0 {
            self.fileSize = size
        }

        self.isScreenshot = asset.mediaSubtypes.contains(.photoScreenshot)
        
        Self.cacheQueue.async(flags: .barrier) {
            Self.assetCache[asset.localIdentifier] = asset
        }
    }
    
    var asset: PHAsset? {
        var cachedAsset: PHAsset?
        Self.cacheQueue.sync {
            cachedAsset = Self.assetCache[id]
        }
        return cachedAsset
    }
    
    func loadAsset() async -> PHAsset? {
        if let cached = asset {
            return cached
        }
        
        let photoId = self.id
        
        return await Task.detached(priority: .userInitiated) {
            let fetchedAsset = PHAsset.fetchAssets(withLocalIdentifiers: [photoId], options: nil).firstObject
            
            if let asset = fetchedAsset {
                Self.cacheQueue.async(flags: .barrier) {
                    Self.assetCache[photoId] = asset
                }
            }
            
            return fetchedAsset
        }.value
    }
    
    static func clearAssetCache() {
        cacheQueue.async(flags: .barrier) {
            assetCache.removeAll()
        }
    }

    private func getFileSize(for asset: PHAsset) -> Int64 {
        let resources = PHAssetResource.assetResources(for: asset)
        
        if let resource = resources.first, let size = resource.value(forKey: "fileSize") as? Int64, size > 0 {
            return size
        }

        return 0
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
