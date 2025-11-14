import SwiftData
import Photos

@Model
final class PhotoModel {
    @Attribute(.unique) var id: String
    var embedding: [Float]?
    var group: PhotoGroupModel?
    var creationDate: Date?
    var fileSize: Int64 = 0
    
    init(asset: PHAsset) {
        self.id = asset.localIdentifier
        self.creationDate = asset.creationDate
        
        let resources = PHAssetResource.assetResources(for: asset)
        
        if let resource = resources.first, let size = resource.value(forKey: "fileSize") as? Int64, size > 0 {
            self.fileSize = size
        }
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

    func isScreenshot() -> Bool {
        asset?.mediaSubtypes.contains(.photoScreenshot) ?? false
    }

    static var similar: FetchDescriptor<PhotoModel> {
        FetchDescriptor(
            predicate: #Predicate<PhotoModel> { $0.group?.type == "similar" }
        )
    }

    static var withEmbedding: FetchDescriptor<PhotoModel> {
        FetchDescriptor(
            predicate: #Predicate<PhotoModel> { $0.embedding != nil }
        )
    }
}
