import SwiftData
import Photos

@Model
final class PhotoModel {
    @Attribute(.unique) var id: String
    @Relationship(deleteRule: .nullify)
    var groups: [PhotoGroupModel] = []

    var embedding: [Float]?
    var creationDate: Date?
    var fileSize: Int64 = 0
    var isScreenshot: Bool = false
    
    init(asset: PHAsset) {
        self.id = asset.localIdentifier
        self.creationDate = asset.creationDate
        
        let resources = PHAssetResource.assetResources(for: asset)
        
        if let resource = resources.first, let size = resource.value(forKey: "fileSize") as? Int64, size > 0 {
            self.fileSize = size
        }

        self.isScreenshot = asset.mediaSubtypes.contains(.photoScreenshot)
    }
    
    var asset: PHAsset? {
        PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject
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
