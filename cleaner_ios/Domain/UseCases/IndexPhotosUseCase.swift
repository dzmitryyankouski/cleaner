import Foundation
import Photos

// MARK: - Index Photos Use Case

/// Use Case для индексации фотографий
final class IndexPhotosUseCase {
    
    // MARK: - Properties
    
    private let assetRepository: AssetRepositoryProtocol
    private let embeddingService: EmbeddingServiceProtocol
    private let concurrentTasks: Int
    
    // MARK: - Initialization
    
    init(
        assetRepository: AssetRepositoryProtocol,
        embeddingService: EmbeddingServiceProtocol,
        concurrentTasks: Int = 10
    ) {
        self.assetRepository = assetRepository
        self.embeddingService = embeddingService
        self.concurrentTasks = concurrentTasks
    }
    
    // MARK: - Public Methods
    
    /// Индексирует все фотографии из библиотеки
    func execute(
        onProgress: @escaping (Int, Int, Photo) async -> Void
    ) async -> Result<[Photo], PhotoIndexingError> {
        // 1. Загружаем ассеты
        let assetsResult = await assetRepository.fetchAssets()
        
        guard case .success(let assets) = assetsResult else {
            if case .failure(let error) = assetsResult {
                return .failure(.assetLoadingFailed(error))
            }
            return .failure(.unknown)
        }
        
        // 2. Индексируем параллельно
        var photos: [Photo] = []
        
        await withTaskGroup(of: (Int, Photo?)?.self) { group in
            var activeTasks = 0
            
            for (index, asset) in assets.enumerated() {
                // Ограничиваем количество параллельных задач
                while activeTasks >= concurrentTasks {
                    if let result = await group.next() {
                        if let (_, photo) = result, let photo = photo {
                            photos.append(photo)
                            await onProgress(assets.count, photos.count, photo)
                        }
                        activeTasks -= 1
                    }
                }
                
                group.addTask { [weak self] in
                    guard let self = self else { return nil }
                    let photo = await self.indexSinglePhoto(asset, index: index)
                    return (index, photo)
                }
                activeTasks += 1
            }
            
            // Обрабатываем оставшиеся результаты
            for await result in group {
                if let (_, photo) = result, let photo = photo {
                    photos.append(photo)
                    await onProgress(assets.count, photos.count, photo)
                }
            }
        }
        
        return .success(photos)
    }
    
    // MARK: - Private Methods
    
    private func indexSinglePhoto(_ asset: PHAsset, index: Int) async -> Photo? {
        // Получаем эмбединг через embeddingService
        // Используем временный workaround с приведением типа
        guard let mobileClipService = embeddingService as? MobileCLIPEmbeddingService else {
            print("❌ EmbeddingService не является MobileCLIPEmbeddingService")
            return nil
        }
        
        let embeddingResult = await mobileClipService.generateEmbeddingFromAsset(asset)
        
        guard case .success(let embedding) = embeddingResult else {
            return nil
        }
        
        // Получаем размер файла
        let fileSizeResult = await assetRepository.getFileSize(for: asset)
        let fileSize = (try? fileSizeResult.get()) ?? 0
        
        return Photo(
            index: index,
            asset: asset,
            embedding: embedding,
            fileSize: fileSize
        )
    }
}

// MARK: - Photo Indexing Error

enum PhotoIndexingError: LocalizedError {
    case assetLoadingFailed(AssetError)
    case embeddingGenerationFailed
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .assetLoadingFailed(let error):
            return "Не удалось загрузить ассеты: \(error.localizedDescription)"
        case .embeddingGenerationFailed:
            return "Не удалось сгенерировать эмбединг"
        case .unknown:
            return "Неизвестная ошибка"
        }
    }
}

