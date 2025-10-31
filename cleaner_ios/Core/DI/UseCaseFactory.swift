import Foundation

// MARK: - Use Case Factory

/// Фабрика для создания Use Cases
final class UseCaseFactory {
    
    // MARK: - Properties
    
    private let serviceFactory: ServiceFactory
    
    // MARK: - Initialization
    
    init(serviceFactory: ServiceFactory = .shared) {
        self.serviceFactory = serviceFactory
    }
    
    // MARK: - Public Methods
    
    /// Создает Use Case для индексации фотографий
    func makeIndexPhotosUseCase() -> IndexPhotosUseCase? {
        guard let embeddingService = serviceFactory.makeEmbeddingService() else {
            print("❌ Не удалось создать embedding service для IndexPhotosUseCase")
            return nil
        }
        
        return IndexPhotosUseCase(
            assetRepository: serviceFactory.makePhotoAssetRepository(),
            embeddingService: embeddingService,
            concurrentTasks: 10
        )
    }
    
    /// Создает Use Case для группировки похожих фотографий
    func makeGroupSimilarPhotosUseCase() -> GroupSimilarPhotosUseCase {
        GroupSimilarPhotosUseCase(
            clusteringService: serviceFactory.makeClusteringService(),
            settingsProvider: serviceFactory.makeSettingsProvider()
        )
    }
    
    /// Создает Use Case для поиска фотографий
    func makeSearchPhotosUseCase() -> SearchPhotosUseCase? {
        guard let embeddingService = serviceFactory.makeEmbeddingService() else {
            print("❌ Не удалось создать embedding service для SearchPhotosUseCase")
            return nil
        }
        
        return SearchPhotosUseCase(
            embeddingService: embeddingService,
            translationService: serviceFactory.makeTranslationService(),
            settingsProvider: serviceFactory.makeSettingsProvider()
        )
    }
    
    /// Создает Use Case для индексации видео
    func makeIndexVideosUseCase() -> IndexVideosUseCase? {
        guard let embeddingService = serviceFactory.makeEmbeddingService() else {
            print("❌ Не удалось создать embedding service для IndexVideosUseCase")
            return nil
        }
        
        return IndexVideosUseCase(
            assetRepository: serviceFactory.makeVideoAssetRepository(),
            videoRepository: serviceFactory.makeVideoAssetRepository(),
            embeddingService: embeddingService,
            imageProcessor: serviceFactory.makeImageProcessingService(),
            concurrentTasks: 5
        )
    }
    
    /// Создает Use Case для группировки похожих видео
    func makeGroupSimilarVideosUseCase() -> GroupSimilarVideosUseCase {
        GroupSimilarVideosUseCase(
            clusteringService: serviceFactory.makeClusteringService(),
            settingsProvider: serviceFactory.makeSettingsProvider()
        )
    }
}

