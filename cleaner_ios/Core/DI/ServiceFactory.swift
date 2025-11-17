import Foundation
import SwiftData

// MARK: - Service Factory

/// Фабрика для создания сервисов с правильными зависимостями
final class ServiceFactory {
    
    // MARK: - Singleton
    
    static let shared = ServiceFactory()
    
    private init() {}
    
    // MARK: - Lazy Properties
    
    private lazy var modelLoader = MLModelLoader()
    
    private lazy var tokenizer: CLIPTokenizer? = {
        try? CLIPTokenizer()
    }()
    
    private lazy var embeddingGenerator: EmbeddingGenerator? = {
        guard let tokenizer = tokenizer else { return nil }
        
        let imageModelResult = modelLoader.loadImageModel()
        let textModelResult = modelLoader.loadTextModel()
        
        guard case .success(let imageModel) = imageModelResult,
              case .success(let textModel) = textModelResult else {
            return nil
        }
        
        return EmbeddingGenerator(
            imageModel: imageModel,
            textModel: textModel,
            tokenizer: tokenizer
        )
    }()
    
    // MARK: - Public Methods
    
    /// Создает сервис для работы с эмбедингами
    func makeEmbeddingService() -> EmbeddingServiceProtocol? {
        guard let generator = embeddingGenerator else {
            print("❌ Не удалось создать embedding generator")
            return nil
        }
        
        return MobileCLIPEmbeddingService(
            embeddingGenerator: generator,
            similarityCalculator: SimilarityCalculator(),
            imageProcessor: ImageProcessingService()
        )
    }
    
    /// Создает репозиторий для работы с фото
    func makePhotoAssetRepository() -> AssetRepositoryProtocol {
        PhotoAssetRepository()
    }
    
    /// Создает репозиторий для работы с видео
    func makeVideoAssetRepository() -> VideoAssetRepository {
        VideoAssetRepository()
    }
    
    /// Создает сервис кластеризации
    func makeClusteringService() -> ClusteringServiceProtocol {
        LSHClusteringService()
    }
    
    /// Создает сервис перевода
    func makeTranslationService() -> TranslationServiceProtocol? {
        guard let apiKey = ConfigService.shared.getValue(for: "GOOGLE_TRANSLATE_API_KEY"),
              !apiKey.isEmpty else {
            print("⚠️ Google Translate API ключ не найден")
            return nil
        }
        
        return GoogleTranslationService(apiKey: apiKey)
    }
    
    /// Создает сервис обработки изображений
    func makeImageProcessingService() -> ImageProcessingProtocol {
        ImageProcessingService()
    }
    
    /// Создает хранилище настроек
    func makeSettingsStorage() -> SettingsStorageProtocol {
        return UserDefaultsSettingsStorage()
    }
    
    /// Создает провайдер настроек
    func makeSettingsProvider() -> SettingsProviderProtocol {
        return UserDefaultsSettingsStorage()
    }

    func makePhotoService(modelContext: ModelContext) -> PhotoService? {
        guard let embeddingService = makeEmbeddingService() else {
            print("❌ Не удалось создать embedding service для PhotoService")
            return nil
        }

        return PhotoService(
            photoAssetRepository: makePhotoAssetRepository(),
            embeddingService: embeddingService,
            clusteringService: makeClusteringService(),
            modelContext: modelContext
        )
    }
}



