import SwiftData
import Photos

@Model
final class PhotoGroupModel: Identifiable {
    @Attribute(.unique) var id: String
    var type: String = "similar" // "similar" или "duplicate"
    var latestDate: Date = Date.distantPast
    var totalSize: Int64 = 0
    
    @Relationship(deleteRule: .nullify, inverse: \PhotoModel.groups)
    var photos: [PhotoModel] = []

    init(id: String, type: String = "similar") {
        self.id = id
        self.type = type
    }
    
    func updateLatestDate() {
        latestDate = photos.compactMap { $0.creationDate }.max() ?? Date.distantPast
    }
    
    func updateTotalSize() {
        totalSize = photos.reduce(0) { $0 + ($1.fileSize ?? 0) }
    }


    static var similar: FetchDescriptor<PhotoGroupModel> {
        FetchDescriptor(
            predicate: #Predicate<PhotoGroupModel> { $0.type == "similar" },
            sortBy: [SortDescriptor(\.latestDate, order: .reverse)]
        )
    }

    static var duplicates: FetchDescriptor<PhotoGroupModel> {
        FetchDescriptor(
            predicate: #Predicate<PhotoGroupModel> { $0.type == "duplicates" },
            sortBy: [SortDescriptor(\.latestDate, order: .reverse)]
        )
    }

    static func apply(filter: Set<FilterPhoto>, sort: SortPhoto, type: String? = nil) -> FetchDescriptor<PhotoGroupModel> {
        let sortDescriptors: [SortDescriptor<PhotoGroupModel>]
        switch sort {
            case .date:
                sortDescriptors = [SortDescriptor(\.latestDate, order: .reverse)]
            case .size:
                sortDescriptors = [SortDescriptor(\.totalSize, order: .reverse)]
        }

        var filterPredicate = #Predicate<PhotoGroupModel> { _ in true }
        var typePredicate = #Predicate<PhotoGroupModel> { _ in true }

        if !filter.isEmpty {
            let hasScreenshots = filter.contains(.screenshots)
            let hasLivePhotos = filter.contains(.livePhotos)
            let hasModified = filter.contains(.modified)
            let hasFavorites = filter.contains(.favorites)

            filterPredicate = #Predicate<PhotoGroupModel> { group in
                (hasScreenshots && group.photos.contains { $0.isScreenshot }) ||
                (hasLivePhotos && group.photos.contains { $0.isLivePhoto }) ||
                (hasModified && group.photos.contains { $0.isModified }) ||
                (hasFavorites && group.photos.contains { $0.isFavorite })
            }
        }

        if let type = type {
            typePredicate = #Predicate<PhotoGroupModel> { group in
                group.type == type
            }
        }

        let predicate = #Predicate<PhotoGroupModel> { group in
            filterPredicate.evaluate(group) && typePredicate.evaluate(group)
        }

        return FetchDescriptor(
            predicate: predicate,
            sortBy: sortDescriptors
        )
    }
}
