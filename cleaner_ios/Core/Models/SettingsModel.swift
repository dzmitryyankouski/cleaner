import Foundation
import SwiftData

@Model
final class SettingsModel {
    static let defaultName = "default"
    
    @Attribute(.unique) var name: String
    var photoSimilarityThreshold: Float
    var searchSimilarityThreshold: Float
    var videoSimilarityThreshold: Float
        
    init(
        name: String = SettingsModel.defaultName,
        photoSimilarityThreshold: Float = 0.95,
        searchSimilarityThreshold: Float = 0.188,
        videoSimilarityThreshold: Float = 0.93
    ) {
        self.name = name
        self.photoSimilarityThreshold = photoSimilarityThreshold
        self.searchSimilarityThreshold = searchSimilarityThreshold
        self.videoSimilarityThreshold = videoSimilarityThreshold
    }

    static var `default`: FetchDescriptor<SettingsModel> {
        FetchDescriptor(
            predicate: #Predicate<SettingsModel> { $0.name == defaultName }
        )
    }
}
