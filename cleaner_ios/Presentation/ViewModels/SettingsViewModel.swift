import Foundation
import Combine

// MARK: - Settings View Model

/// ViewModel для управления настройками приложения
@MainActor
final class SettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Текущие настройки
    @Published var settings: AppSettings
    
    // MARK: - Dependencies
    
    private let settingsStorage: SettingsStorageProtocol
    
    // MARK: - Initialization
    
    init(settingsStorage: SettingsStorageProtocol) {
        self.settingsStorage = settingsStorage
        self.settings = settingsStorage.loadSettings()
        
        print("⚙️ SettingsViewModel инициализирован")
    }
    
    // MARK: - Public Methods
    
    /// Обновляет порог похожести для фотографий
    func updatePhotoSimilarity(_ value: Float) {
        settings.photoSimilarityThreshold = value
        saveSettings()
    }
    
    /// Обновляет порог похожести для поиска
    func updateSearchSimilarity(_ value: Float) {
        settings.searchSimilarityThreshold = value
        saveSettings()
    }
    
    /// Обновляет порог похожести для видео
    func updateVideoSimilarity(_ value: Float) {
        settings.videoSimilarityThreshold = value
        saveSettings()
    }
    
    /// Сбрасывает настройки к значениям по умолчанию
    func resetToDefaults() {
        settings = .default
        saveSettings()
        print("🔄 Настройки сброшены к значениям по умолчанию")
    }
    
    // MARK: - Formatting Helpers
    
    /// Форматирует значение как процент
    func formatAsPercentage(_ value: Float) -> String {
        return String(format: "%.1f", value * 100)
    }
    
    // MARK: - Private Methods
    
    private func saveSettings() {
        settingsStorage.saveSettings(settings)
    }
}

