import Foundation

// MARK: - Settings Provider Protocol

/// Протокол для предоставления настроек приложения
protocol SettingsProviderProtocol {
    
    /// Получает текущие настройки приложения
    func getSettings() -> AppSettings
}

