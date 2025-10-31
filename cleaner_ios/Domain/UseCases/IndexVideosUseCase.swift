import Foundation
import Photos
import AVFoundation

// MARK: - Index Videos Use Case

/// Use Case для индексации видео
final class IndexVideosUseCase {
    
    // MARK: - Properties
    
    private let assetRepository: AssetRepositoryProtocol
    private let videoRepository: VideoAssetRepository
    private let embeddingService: EmbeddingServiceProtocol
    private let imageProcessor: ImageProcessingProtocol
    private let concurrentTasks: Int
    
    // MARK: - Initialization
    
    init(
        assetRepository: AssetRepositoryProtocol,
        videoRepository: VideoAssetRepository,
        embeddingService: EmbeddingServiceProtocol,
        imageProcessor: ImageProcessingProtocol,
        concurrentTasks: Int = 5
    ) {
        self.assetRepository = assetRepository
        self.videoRepository = videoRepository
        self.embeddingService = embeddingService
        self.imageProcessor = imageProcessor
        self.concurrentTasks = concurrentTasks
    }
    
    // MARK: - Public Methods
    
    /// Индексирует все видео из библиотеки
    func execute(
        onProgress: @escaping (Int, Int, Video) async -> Void
    ) async -> Result<[Video], VideoIndexingError> {
        // 1. Загружаем видео ассеты
        let assetsResult = await assetRepository.fetchAssets()
        
        guard case .success(let assets) = assetsResult else {
            if case .failure(let error) = assetsResult {
                return .failure(.assetLoadingFailed(error))
            }
            return .failure(.unknown)
        }
        
        // 2. Индексируем параллельно
        var videos: [Video] = []
        
        await withTaskGroup(of: (Int, Video?)?.self) { group in
            var activeTasks = 0
            
            for (index, asset) in assets.enumerated() {
                // Ограничиваем количество параллельных задач
                while activeTasks >= concurrentTasks {
                    if let result = await group.next() {
                        if let (_, video) = result, let video = video {
                            videos.append(video)
                            await onProgress(assets.count, videos.count, video)
                        }
                        activeTasks -= 1
                    }
                }
                
                group.addTask { [weak self] in
                    guard let self = self else { return nil }
                    let video = await self.indexSingleVideo(asset)
                    return (index, video)
                }
                activeTasks += 1
            }
            
            // Обрабатываем оставшиеся результаты
            for await result in group {
                if let (_, video) = result, let video = video {
                    videos.append(video)
                    await onProgress(assets.count, videos.count, video)
                }
            }
        }
        
        return .success(videos)
    }
    
    // MARK: - Private Methods
    
    private func indexSingleVideo(_ asset: PHAsset) async -> Video? {
        // Получаем размер файла
        let fileSizeResult = await videoRepository.getFileSize(for: asset)
        let fileSize = (try? fileSizeResult.get()) ?? 0
        
        // Генерируем эмбединг из кадров видео
        let embeddingResult = await generateVideoEmbedding(for: asset)
        
        guard case .success(let embedding) = embeddingResult else {
            return nil
        }
        
        return Video(
            asset: asset,
            duration: asset.duration,
            fileSize: fileSize,
            creationDate: asset.creationDate,
            modificationDate: asset.modificationDate,
            embedding: embedding
        )
    }
    
    private func generateVideoEmbedding(for asset: PHAsset) async -> Result<[Float], VideoIndexingError> {
        // Получаем AVAsset
        guard let avAsset = await videoRepository.getAVAsset(for: asset) else {
            return .failure(.videoProcessingFailed)
        }
        
        // Извлекаем кадры
        let framesResult = await extractFrames(from: avAsset, duration: asset.duration)
        
        guard case .success(let frames) = framesResult, !frames.isEmpty else {
            return .failure(.frameExtractionFailed)
        }
        
        // Генерируем эмбединги для каждого кадра
        var embeddings: [[Float]] = []
        
        for frame in frames {
            let embeddingResult = await embeddingService.generateImageEmbedding(from: frame)
            if case .success(let embedding) = embeddingResult {
                embeddings.append(embedding)
            }
        }
        
        guard !embeddings.isEmpty else {
            return .failure(.embeddingGenerationFailed)
        }
        
        // Вычисляем средний эмбединг
        let averageEmbedding = calculateAverageEmbedding(embeddings)
         
        return .success(averageEmbedding)
    }
    
    private func extractFrames(from avAsset: AVAsset, duration: TimeInterval) async -> Result<[CVPixelBuffer], VideoIndexingError> {
        let generator = AVAssetImageGenerator(asset: avAsset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceAfter = .zero
        generator.requestedTimeToleranceBefore = .zero
        
        // Извлекаем кадры каждые 4 секунды
        var times: [CMTime] = []
        let numberOfSeconds = Int(duration)
        
        for i in stride(from: 0, through: numberOfSeconds, by: 4) {
            let time = CMTime(seconds: Double(i), preferredTimescale: 600)
            times.append(time)
        }
        
        // Если видео короткое, берем кадр из середины
        if times.isEmpty {
            let time = CMTime(seconds: duration / 2.0, preferredTimescale: 600)
            times.append(time)
        }
        
        // Параллельное извлечение кадров
        var frames: [CVPixelBuffer] = []
        
        await withTaskGroup(of: CVPixelBuffer?.self) { group in
            for time in times {
                group.addTask { [weak self] in
                    await self?.extractFrame(from: generator, at: time)
                }
            }
            
            for await pixelBuffer in group {
                if let pixelBuffer = pixelBuffer {
                    frames.append(pixelBuffer)
                }
            }
        }
        
        return frames.isEmpty ? .failure(.frameExtractionFailed) : .success(frames)
    }
    
    private func extractFrame(from generator: AVAssetImageGenerator, at time: CMTime) async -> CVPixelBuffer? {
        return await withCheckedContinuation { continuation in
            generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { [weak self] _, cgImage, _, _, error in
                guard let self = self, error == nil, let cgImage = cgImage else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let result = self.imageProcessor.convertCGImageToPixelBuffer(
                    cgImage,
                    targetSize: CGSize(width: 256, height: 256)
                )
                
                if case .success(let pixelBuffer) = result {
                    continuation.resume(returning: pixelBuffer)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    private func calculateAverageEmbedding(_ embeddings: [[Float]]) -> [Float] {
        guard !embeddings.isEmpty else { return [] }
        
        let embeddingSize = embeddings[0].count
        var averageEmbedding = [Float](repeating: 0, count: embeddingSize)
        
        // Суммируем все эмбединги
        for embedding in embeddings {
            for i in 0..<embeddingSize {
                averageEmbedding[i] += embedding[i]
            }
        }
        
        // Делим на количество эмбедингов
        let count = Float(embeddings.count)
        for i in 0..<embeddingSize {
            averageEmbedding[i] /= count
        }
        
        return averageEmbedding
    }
}

// MARK: - Video Indexing Error

enum VideoIndexingError: LocalizedError {
    case assetLoadingFailed(AssetError)
    case videoProcessingFailed
    case frameExtractionFailed
    case embeddingGenerationFailed
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .assetLoadingFailed(let error):
            return "Не удалось загрузить видео: \(error.localizedDescription)"
        case .videoProcessingFailed:
            return "Не удалось обработать видео"
        case .frameExtractionFailed:
            return "Не удалось извлечь кадры из видео"
        case .embeddingGenerationFailed:
            return "Не удалось сгенерировать эмбединги для видео"
        case .unknown:
            return "Неизвестная ошибка"
        }
    }
}

