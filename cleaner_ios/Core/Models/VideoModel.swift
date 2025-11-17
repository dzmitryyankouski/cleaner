import SwiftData
import Photos
import AVFoundation

@Model
final class VideoModel {
    @Attribute(.unique) var id: String
    @Relationship(deleteRule: .nullify)
    var groups: [VideoGroupModel] = []
    
    var duration: TimeInterval
    var creationDate: Date?
    var modificationDate: Date?
    var embedding: [Float]?
    var fileSize: Int64?

    init(asset: PHAsset) {
        self.id = asset.localIdentifier
        self.duration = asset.duration
        self.creationDate = asset.creationDate
        self.modificationDate = asset.modificationDate
    }

    static func getFileSize(for asset: PHAsset, completion: @escaping (Int64) -> Void) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = false
            
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
            if let urlAsset = avAsset as? AVURLAsset {
                do {
                    let resourceValues = try urlAsset.url.resourceValues(forKeys: [.fileSizeKey])
                    let fileSize = Int64(resourceValues.fileSize ?? 0)
                    completion(fileSize)
                } catch {
                    completion(0)
                }
            } else {
                completion(0)
            }
        }
    }

    static var similar: FetchDescriptor<VideoModel> {
        FetchDescriptor(
            predicate: #Predicate<VideoModel> { video in
                video.groups.contains { $0.type == "similar" }
            }
        )
    }

    static var withEmbedding: FetchDescriptor<VideoModel> {
        FetchDescriptor(
            predicate: #Predicate<VideoModel> { $0.embedding != nil }
        )
    }
}