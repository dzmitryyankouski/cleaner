import Foundation

// MARK: - App Settings

/// Value Object для настроек приложения
struct AppSettings: Codable, Equatable {
    
    // MARK: - Photo Settings
    
    /// Порог похожести для группировки фотографий (0.0 - 1.0)
    var photoSimilarityThreshold: Float
    
    /// Порог похожести для поиска фотографий (0.15 - 0.20)
    var searchSimilarityThreshold: Float
    
    // MARK: - Video Settings
    
    /// Порог похожести для группировки видео (0.0 - 1.0)
    var videoSimilarityThreshold: Float
    
    // MARK: - Defaults
    
    static let `default` = AppSettings(
        photoSimilarityThreshold: 0.95,
        searchSimilarityThreshold: 0.188,
        videoSimilarityThreshold: 0.93
    )
    
    // MARK: - Validation
    
    /// Валидация настроек
    func validated() -> AppSettings {
        return AppSettings(
            photoSimilarityThreshold: max(0.0, min(1.0, photoSimilarityThreshold)),
            searchSimilarityThreshold: max(0.15, min(0.20, searchSimilarityThreshold)),
            videoSimilarityThreshold: max(0.0, min(1.0, videoSimilarityThreshold))
        )
    }
}

