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