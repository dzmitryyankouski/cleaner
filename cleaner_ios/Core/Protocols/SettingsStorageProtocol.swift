import Foundation

// MARK: - Settings Storage Protocol

/// Протокол для сохранения и загрузки настроек приложения
protocol SettingsStorageProtocol {
    
    /// Загружает настройки из хранилища
    func loadSettings() -> AppSettings
    
    /// Сохраняет настройки в хранилище
    /// - Parameter settings: Настройки для сохранения
    func saveSettings(_ settings: AppSettings)
}

