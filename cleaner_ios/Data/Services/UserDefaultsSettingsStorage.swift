import Foundation

// MARK: - UserDefaults Settings Storage

/// Реализация хранилища настроек через UserDefaults
final class UserDefaultsSettingsStorage: SettingsStorageProtocol, SettingsProviderProtocol {
    
    // MARK: - Constants
    
    private enum Keys {
        static let settings = "app_settings"
    }
    
    // MARK: - Properties
    
    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    // MARK: - Initialization
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }
    
    // MARK: - SettingsStorageProtocol
    
    func loadSettings() -> AppSettings {
        return getSettings()
    }
    
    // MARK: - SettingsProviderProtocol
    
    func getSettings() -> AppSettings {
        guard let data = userDefaults.data(forKey: Keys.settings),
              let settings = try? decoder.decode(AppSettings.self, from: data) else {
            return .default
        }
        
        return settings.validated()
    }
    
    func saveSettings(_ settings: AppSettings) {
        let validatedSettings = settings.validated()
        
        guard let data = try? encoder.encode(validatedSettings) else {
            print("❌ Не удалось закодировать настройки")
            return
        }
        
        userDefaults.set(data, forKey: Keys.settings)
        print("✅ Настройки сохранены в UserDefaults")
    }
}

