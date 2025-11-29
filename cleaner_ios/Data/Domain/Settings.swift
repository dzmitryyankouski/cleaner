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
        
        if let items = items, !items.isEmpty {
            self.values = items.first!
        } else {
            let newSettings = SettingsModel()
            modelContext.insert(newSettings)
            try? modelContext.save()
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
}
