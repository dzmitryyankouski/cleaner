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
    var isModified: Bool = false
    var isFavorite: Bool = false

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

    static func apply(filter: Set<FilterVideo>, sort: SortVideo, type: String? = nil) -> FetchDescriptor<VideoModel> {
        let sortDescriptors: [SortDescriptor<VideoModel>]
        switch sort {
            case .date:
                sortDescriptors = [SortDescriptor(\.creationDate, order: .reverse)]
            case .size:
                sortDescriptors = [SortDescriptor(\.fileSize, order: .reverse)]
        }

        var filterPredicate = #Predicate<VideoModel> { _ in true }
        var groupPredicate = #Predicate<VideoModel> { _ in true }

        if !filter.isEmpty {
            let hasModified = filter.contains(.modified)
            let hasFavorites = filter.contains(.favorites)

            filterPredicate = #Predicate<VideoModel> { video in
                (hasModified && video.isModified) ||
                (hasFavorites && video.isFavorite)
            }
        }

        if let type = type {
            groupPredicate = #Predicate<VideoModel> { video in
                video.groups.contains { $0.type == type }
            }
        }

        let predicate = #Predicate<VideoModel> { video in
            filterPredicate.evaluate(video) && groupPredicate.evaluate(video)
        }
        
        return FetchDescriptor(
            predicate: predicate,
            sortBy: sortDescriptors
        )
    }
}
