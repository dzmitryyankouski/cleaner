import Foundation

// MARK: - Search Photos Use Case

/// Use Case для поиска фотографий по текстовому запросу
final class SearchPhotosUseCase {
    
    // MARK: - Properties
    
    private let embeddingService: EmbeddingServiceProtocol
    private let translationService: TranslationServiceProtocol?
    private let settingsProvider: SettingsProviderProtocol
    
    // MARK: - Initialization
    
    init(
        embeddingService: EmbeddingServiceProtocol,
        translationService: TranslationServiceProtocol? = nil,
        settingsProvider: SettingsProviderProtocol
    ) {
        self.embeddingService = embeddingService
        self.translationService = translationService
        self.settingsProvider = settingsProvider
    }
    
    // MARK: - Public Methods
    
    /// Ищет фотографии по текстовому запросу используя настройки
    func execute(
        query: String,
        photos: [Photo]
    ) async -> Result<[SearchResult<Photo>], SearchError> {
        let minSimilarity = settingsProvider.getSettings().searchSimilarityThreshold
        return await execute(query: query, photos: photos, minSimilarity: minSimilarity)
    }
    
    /// Ищет фотографии по текстовому запросу с указанным порогом
    func execute(
        query: String,
        photos: [Photo],
        minSimilarity: Float
    ) async -> Result<[SearchResult<Photo>], SearchError> {
        // 1. Переводим запрос (если есть сервис перевода)
        var searchQuery = query
        if let translationService = translationService {
            if case .success(let translated) = await translationService.translate(query, to: "en") {
                searchQuery = translated
            }
        }
        
        // 2. Генерируем эмбединг для запроса
        let queryEmbeddingResult = await embeddingService.generateTextEmbedding(from: searchQuery)
        
        guard case .success(let queryEmbedding) = queryEmbeddingResult else {
            if case .failure(let error) = queryEmbeddingResult {
                return .failure(.embeddingGenerationFailed(error))
            }
            return .failure(.unknown)
        }
        
        // 3. Вычисляем схожесть для каждой фотографии
        var results: [SearchResult<Photo>] = []
        
        for photo in photos {
            let similarity = embeddingService.calculateSimilarity(
                queryEmbedding,
                photo.embedding.values
            )
            
            if similarity >= minSimilarity {
                results.append(SearchResult(item: photo, similarity: similarity))
            }
        }
        
        // 4. Сортируем по убыванию схожести
        results.sort { $0.similarity > $1.similarity }
        
        return .success(results)
    }
}

// MARK: - Search Error

enum SearchError: LocalizedError {
    case embeddingGenerationFailed(EmbeddingError)
    case translationFailed
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .embeddingGenerationFailed(let error):
            return "Не удалось сгенерировать эмбединг: \(error.localizedDescription)"
        case .translationFailed:
            return "Не удалось перевести запрос"
        case .unknown:
            return "Неизвестная ошибка"
        }
    }
}

