import Foundation
import SwiftUI
import SwiftData

final class AppDependencyContainer {
    static let shared = AppDependencyContainer()
    
    private let serviceFactory: ServiceFactory
    private let modelContainer: ModelContainer
    
    private init() {
        self.serviceFactory = ServiceFactory.shared
        do {
            self.modelContainer = try ModelContainer(
                for: PhotoModel.self,
                PhotoGroupModel.self,
                VideoModel.self,
                VideoGroupModel.self,
                SettingsModel.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            fatalError("❌ Не удалось создать ModelContainer: \(error)")
        }
    }
    
    func getModelContainer() -> ModelContainer {
        return modelContainer
    }
    
    @MainActor
    func makePhotoLibrary() -> PhotoLibrary? {
        guard let embeddingService = serviceFactory.makeEmbeddingService() else {
            print("❌ Не удалось создать EmbeddingService для PhotoLibrary")
            return nil
        }

        let photoContext = ModelContext(modelContainer)

        return PhotoLibrary(
            photoAssetRepository: serviceFactory.makePhotoAssetRepository(),
            embeddingService: embeddingService,
            clusteringService: serviceFactory.makeClusteringService(),
            translationService: serviceFactory.makeTranslationService(),
            modelContext: photoContext
        )
    }

    @MainActor
    func makeVideoLibrary() -> VideoLibrary? {
        guard let embeddingService = serviceFactory.makeEmbeddingService() else {
            print("❌ Не удалось создать EmbeddingService для VideoLibrary")
            return nil
        }

        let videoContext = ModelContext(modelContainer)

        return VideoLibrary(
            videoAssetRepository: serviceFactory.makeVideoAssetRepository(),
            embeddingService: embeddingService,
            imageProcessor: serviceFactory.makeImageProcessingService(),
            clusteringService: serviceFactory.makeClusteringService(),
            translationService: serviceFactory.makeTranslationService(),
            modelContext: videoContext
        )
    }
    
    @MainActor
    func makeSettings() -> Settings {
        let settingsContext = ModelContext(modelContainer)

        return Settings(modelContext: settingsContext)
    }
}

