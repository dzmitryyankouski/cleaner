import SwiftData
import Photos

@Model
final class PhotoGroupModel {
    @Attribute(.unique) var id: String
    var type: String = "similar" // "similar" или "duplicate"
    var latestDate: Date = Date.distantPast
    
    @Relationship(deleteRule: .nullify, inverse: \PhotoModel.group)
    var photos: [PhotoModel] = []

    init(id: String, type: String = "similar") {
        self.id = id
        self.type = type
    }
    
    func updateLatestDate() {
        latestDate = photos.compactMap { $0.creationDate }.max() ?? Date.distantPast
    }

    static var similar: FetchDescriptor<PhotoGroupModel> {
        FetchDescriptor(
            predicate: #Predicate<PhotoGroupModel> { $0.type == "similar" },
            sortBy: [SortDescriptor(\.latestDate, order: .reverse)]
        )
    }
}
