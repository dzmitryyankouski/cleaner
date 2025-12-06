import SwiftData
import Photos

@Model
final class VideoGroupModel: Identifiable {
    @Attribute(.unique) var id: String
    var type: String = "similar"
    var latestDate: Date = Date.distantPast
    var totalSize: Int64 = 0
    
    @Relationship(deleteRule: .nullify, inverse: \VideoModel.groups)
    var videos: [VideoModel] = []

    init(id: String, type: String = "similar") {
        self.id = id
        self.type = type
    }
    
    func updateLatestDate() {
        latestDate = videos.compactMap { $0.creationDate }.max() ?? Date.distantPast
    }
    
    func updateTotalSize() {
        totalSize = videos.reduce(0) { $0 + ($1.fileSize ?? 0) }
    }

    static var similar: FetchDescriptor<VideoGroupModel> {
        FetchDescriptor(
            predicate: #Predicate<VideoGroupModel> { $0.type == "similar" },
            sortBy: [SortDescriptor(\.latestDate, order: .reverse)]
        )
    }

    static func apply(filter: Set<FilterVideo>, sort: SortVideo, type: String? = nil) -> FetchDescriptor<VideoGroupModel> {
        let sortDescriptors: [SortDescriptor<VideoGroupModel>]
        switch sort {
            case .date:
                sortDescriptors = [SortDescriptor(\.latestDate, order: .reverse)]
            case .size:
                sortDescriptors = [SortDescriptor(\.totalSize, order: .reverse)]
        }

        var filterPredicate = #Predicate<VideoGroupModel> { _ in true }
        var typePredicate = #Predicate<VideoGroupModel> { _ in true }

        if !filter.isEmpty {
            let hasModified = filter.contains(.modified)
            let hasFavorites = filter.contains(.favorites)

            filterPredicate = #Predicate<VideoGroupModel> { group in
                (hasModified && group.videos.contains { $0.isModified }) ||
                (hasFavorites && group.videos.contains { $0.isFavorite })
            }
        }

        if let type = type {
            typePredicate = #Predicate<VideoGroupModel> { group in
                group.type == type
            }
        }

        let predicate = #Predicate<VideoGroupModel> { group in
            filterPredicate.evaluate(group) && typePredicate.evaluate(group)
        }

        return FetchDescriptor(
            predicate: predicate,
            sortBy: sortDescriptors
        )
    }
}
