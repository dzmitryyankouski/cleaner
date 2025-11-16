import Foundation
import Observation
import SwiftData

@Observable
class Settings {
    var values: SettingsModel
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext

        let items = try? modelContext.fetch(SettingsModel.default)

        if let item = items?.first {
            self.values = item
        } else {
            let newSettings = SettingsModel()
            modelContext.insert(newSettings)
            self.values = newSettings
        }
    }

    func save() {
        do {
            try modelContext.save()
        } catch {
            print("❌ Не удалось сохранить настройки: \(error)")
        }
    }

    func resetToDefaults() {
        values.photoSimilarityThreshold = 0.95
        values.searchSimilarityThreshold = 0.188
        values.videoSimilarityThreshold = 0.93

        save()
    }
}
