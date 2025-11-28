import Foundation
import SwiftData

final class ServiceFactory {
    static let shared = ServiceFactory()
    
    private init() {}
        
    private lazy var tokenizer: CLIPTokenizer? = {
        try? CLIPTokenizer()
    }()
    
    private lazy var embeddingGenerator: EmbeddingGenerator? = {
        guard let tokenizer = tokenizer else { return nil }
        
        do {
            return try EmbeddingGenerator(tokenizer: tokenizer)
        } catch {
            print("❌ Не удалось загрузить модели: \(error)")
            return nil
        }
    }()
    
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
    
    func makePhotoAssetRepository() -> AssetRepositoryProtocol {
        PhotoAssetRepository()
    }
    
    func makeVideoAssetRepository() -> VideoAssetRepository {
        VideoAssetRepository()
    }
    
    func makeClusteringService() -> ClusteringServiceProtocol {
        LSHClusteringService()
    }
    
    func makeTranslationService() -> TranslationServiceProtocol? {
        guard let apiKey = ConfigService.shared.getValue(for: "GOOGLE_TRANSLATE_API_KEY"),
              !apiKey.isEmpty else {
            print("⚠️ Google Translate API ключ не найден")
            return nil
        }
        
        return GoogleTranslationService(apiKey: apiKey)
    }
    
    func makeImageProcessingService() -> ImageProcessingProtocol {
        ImageProcessingService()
    }
}
