import SwiftData
import Photos

@Model
final class VideoGroupModel {
    @Attribute(.unique) var id: String
    var type: String = "similar"
    var latestDate: Date = Date.distantPast
    
    @Relationship(deleteRule: .nullify, inverse: \VideoModel.groups)
    var videos: [VideoModel] = []

    init(id: String, type: String = "similar") {
        self.id = id
        self.type = type
    }
    
    func updateLatestDate() {
        latestDate = videos.compactMap { $0.creationDate }.max() ?? Date.distantPast
    }

    static var similar: FetchDescriptor<VideoGroupModel> {
        FetchDescriptor(
            predicate: #Predicate<VideoGroupModel> { $0.type == "similar" },
            sortBy: [SortDescriptor(\.latestDate, order: .reverse)]
        )
    }
}
