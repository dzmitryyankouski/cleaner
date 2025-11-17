import Foundation
import SwiftUI
import SwiftData

// MARK: - App Dependency Container

/// Контейнер зависимостей приложения
final class AppDependencyContainer {
    
    // MARK: - Singleton
    
    static let shared = AppDependencyContainer()
    
    // MARK: - Properties
    
    private let serviceFactory: ServiceFactory
    private let useCaseFactory: UseCaseFactory
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    private init() {
        self.serviceFactory = ServiceFactory.shared
        self.useCaseFactory = UseCaseFactory(serviceFactory: serviceFactory)
        
        // Создаем ModelContainer
        do {
            self.modelContainer = try ModelContainer(
                for: PhotoModel.self,
                PhotoGroupModel.self,
                VideoModel.self,
                VideoGroupModel.self,
                SettingsModel.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
            self.modelContext = ModelContext(modelContainer)
        } catch {
            fatalError("❌ Не удалось создать ModelContainer: \(error)")
        }
    }
    
    // MARK: - Model Container Access
    
    /// Возвращает ModelContainer для использования в SwiftUI
    func getModelContainer() -> ModelContainer {
        return modelContainer
    }
    
    /// Создает PhotoViewModel с правильными зависимостями
    @MainActor
    func makePhotoViewModel() -> PhotoViewModel? {
        guard let indexPhotosUseCase = useCaseFactory.makeIndexPhotosUseCase(),
              let searchPhotosUseCase = useCaseFactory.makeSearchPhotosUseCase() else {
            print("❌ Не удалось создать Use Cases для PhotoViewModel")
            return nil
        }
        
        return PhotoViewModel(
            indexPhotosUseCase: indexPhotosUseCase,
            groupSimilarPhotosUseCase: useCaseFactory.makeGroupSimilarPhotosUseCase(),
            searchPhotosUseCase: searchPhotosUseCase
        )
    }
    
    /// Создает VideoViewModel с правильными зависимостями
    @MainActor
    func makeVideoViewModel() -> VideoViewModel? {
        guard let indexVideosUseCase = useCaseFactory.makeIndexVideosUseCase() else {
            print("❌ Не удалось создать Use Cases для VideoViewModel")
            return nil
        }
        
        return VideoViewModel(
            indexVideosUseCase: indexVideosUseCase,
            groupSimilarVideosUseCase: useCaseFactory.makeGroupSimilarVideosUseCase()
        )
    }

    @MainActor
    func makePhotoLibrary() -> PhotoLibrary? {
        guard let photoService = serviceFactory.makePhotoService(modelContext: modelContext) else {
            print("❌ Не удалось создать PhotoService для PhotoLibrary")
            return nil
        }

        return PhotoLibrary(photoService: photoService)
    }

    @MainActor
    func makeVideoLibrary() -> VideoLibrary? {
        guard let embeddingService = serviceFactory.makeEmbeddingService() else {
            print("❌ Не удалось создать EmbeddingService для VideoLibrary")
            return nil
        }

        return VideoLibrary(
            videoAssetRepository: serviceFactory.makeVideoAssetRepository(),
            embeddingService: embeddingService,
            imageProcessor: serviceFactory.makeImageProcessingService(),
            clusteringService: serviceFactory.makeClusteringService(),
            modelContext: modelContext
        )
    }
    
    @MainActor
    func makeSettings() -> Settings {
        return Settings(modelContext: modelContext)
    }
}

