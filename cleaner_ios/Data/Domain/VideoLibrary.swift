import Foundation
import Observation
import SwiftData
import Photos
import AVFoundation
import CoreVideo

@Observable
class VideoLibrary {
    var indexing: Bool = false
    var indexed: Int = 0
    var total: Int = 0

    var videos: [VideoModel] = []
    var videosFileSize: Int64 = 0
    
    var similarGroups: [VideoGroupModel] = []
    var similarVideos: [VideoModel] = []
    var similarVideosFileSize: Int64 = 0

    private let videoAssetRepository: VideoAssetRepository
    private let embeddingService: EmbeddingServiceProtocol
    private let imageProcessor: ImageProcessingProtocol
    private let clusteringService: ClusteringServiceProtocol
    private let translationService: TranslationServiceProtocol?
    private let concurrentTasks = 5
    private let context: ModelContext
    private let settings: Settings

    init(
        videoAssetRepository: VideoAssetRepository,
        embeddingService: EmbeddingServiceProtocol,
        imageProcessor: ImageProcessingProtocol,
        clusteringService: ClusteringServiceProtocol,
        translationService: TranslationServiceProtocol? = nil,
        settings: Settings,
        modelContext: ModelContext
    ) {
        self.videoAssetRepository = videoAssetRepository
        self.embeddingService = embeddingService
        self.imageProcessor = imageProcessor
        self.clusteringService = clusteringService
        self.translationService = translationService
        self.context = modelContext
        self.settings = settings

        Task {
            await loadVideos()
        }
    }

    func loadVideos() async {
        indexing = true

        videos = await getAllVideos()
        total = videos.count
        
        await indexVideos()
        
        await regroup()

        videosFileSize = videos.reduce(0) { $0 + ($1.fileSize ?? 0) }

        indexing = false
    }

    func regroup() async {
        let threshold = settings.values.videoSimilarityThreshold
        await groupSimilar(threshold: threshold)

        similarGroups = getSimilarGroups()
        similarVideos = getSimilarVideos()
        similarVideosFileSize = similarVideos.reduce(0) { $0 + ($1.fileSize ?? 0) }
    }

    func getAllVideos() async -> [VideoModel] {
        let assetsResult = await videoAssetRepository.fetchAssets()

        guard case .success(let assets) = assetsResult else {
            print("❌ Не удалось загрузить видео")
            return []
        }

        for asset in assets {
            let assetId = asset.localIdentifier
            if let _ = try? context.fetch(FetchDescriptor<VideoModel>(predicate: #Predicate<VideoModel> { $0.id == assetId })).first {
                continue
            }
            
            let video = VideoModel(asset: asset)
            context.insert(video)
        }

        do {
            try context.save()
        } catch {
            print("❌ Ошибка при сохранении видео: \(error)")
            return []
        }
        
        return (try? context.fetch(FetchDescriptor<VideoModel>())) ?? []
    }

    func indexVideos() async {
        guard let videos = try? context.fetch(FetchDescriptor<VideoModel>(predicate: #Predicate<VideoModel> { $0.embedding == nil })) else {
            print("❌ Нет видео для индексации")
            return
        }

        // guard let videos = try? context.fetch(FetchDescriptor<VideoModel>()) else {
        //     print("❌ Нет видео для индексации")
        //     return
        // }

        await withTaskGroup(of: Void.self) { group in
            var activeTasks = 0
            
            for video in videos {
                while activeTasks >= concurrentTasks {
                    await group.next()
                    activeTasks -= 1
                }

                group.addTask { [weak self] in
                    guard let self = self else { return }
                    let videoId = video.id
                    
                    let assets = PHAsset.fetchAssets(withLocalIdentifiers: [videoId], options: nil)
                    guard let asset = assets.firstObject else { return }
                    
                    let fileSizeResult = await self.videoAssetRepository.getFileSize(for: asset)
                    let fileSize = (try? fileSizeResult.get()) ?? 0
                    
                    let embeddingResult = await self.generateVideoEmbedding(for: asset)
                    
                    if case .success(let embedding) = embeddingResult {
                        await MainActor.run {
                            video.fileSize = fileSize
                            video.embedding = embedding
                            self.indexed += 1
                        }
                    }
                }

                activeTasks += 1
            }
            
            while activeTasks > 0 {
                await group.next()
                activeTasks -= 1
            }
        }

        do {
            try context.save()
        } catch {
            print("❌ Ошибка при сохранении контекста: \(error)")
        }
    }

    func getSimilarGroups() -> [VideoGroupModel] {
        return (try? context.fetch(VideoGroupModel.similar)) ?? []
    }

    func getSimilarVideos() -> [VideoModel] {
        return (try? context.fetch(VideoModel.similar)) ?? []
    }

    func groupSimilar(threshold: Float) async {
        let groups = getSimilarGroups()

        for group in groups {
            context.delete(group)
        }

        await group(type: "similar", threshold: threshold)
    }
    
    private func group(type: String, threshold: Float) async {
        guard let videos = try? context.fetch(FetchDescriptor<VideoModel>()) else {
            print("❌ Нет видео для группировки")
            return
        }

        print("🔍 Видео для группировки: \(videos.count)")
        
        guard videos.count > 1 else { return }

        print("Начинаем группировку видео")
        
        let embeddings = videos.compactMap { $0.embedding }
        let groupIndices = await clusteringService.groupEmbeddings(embeddings, threshold: threshold)

        print("🔍 Эмбединги: \(embeddings.count)")

        for indices in groupIndices {
            let groupVideos = indices.compactMap { validIndex -> VideoModel? in
                guard videos.indices.contains(validIndex) else { return nil }
                return videos[validIndex]
            }
            
            guard groupVideos.count > 1 else { continue }
            
            let groupId = UUID().uuidString
            let group = VideoGroupModel(id: groupId, type: type)
            
            group.videos = groupVideos

            for video in groupVideos {
                if !video.groups.contains(where: { $0.id == group.id }) {
                    video.groups.append(group)
                }
            }
            
            group.updateLatestDate()
            context.insert(group)
        }

        do {
            try context.save()
        } catch {
            print("❌ Ошибка при сохранении контекста: \(error)")
        }
    }

    private func generateVideoEmbedding(for asset: PHAsset) async -> Result<[Float], VideoIndexingError> {
        guard let avAsset = await videoAssetRepository.getAVAsset(for: asset) else {
            return .failure(.videoProcessingFailed)
        }
        
        let framesResult = await extractFrames(from: avAsset, duration: asset.duration)
        
        guard case .success(let frames) = framesResult, !frames.isEmpty else {
            return .failure(.frameExtractionFailed)
        }
        
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
        
        let averageEmbedding = calculateAverageEmbedding(embeddings)
         
        return .success(averageEmbedding)
    }

    private func extractFrames(from avAsset: AVAsset, duration: TimeInterval) async -> Result<[CVPixelBuffer], VideoIndexingError> {
        let generator = AVAssetImageGenerator(asset: avAsset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceAfter = .zero
        generator.requestedTimeToleranceBefore = .zero
        
        var times: [CMTime] = []
        let numberOfSeconds = Int(duration)
        
        for i in stride(from: 0, through: numberOfSeconds, by: 4) {
            let time = CMTime(seconds: Double(i), preferredTimescale: 600)
            times.append(time)
        }
        
        if times.isEmpty {
            let time = CMTime(seconds: duration / 2.0, preferredTimescale: 600)
            times.append(time)
        }
        
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
        
        for embedding in embeddings {
            for i in 0..<embeddingSize {
                averageEmbedding[i] += embedding[i]
            }
        }
        
        let count = Float(embeddings.count)
        for i in 0..<embeddingSize {
            averageEmbedding[i] /= count
        }
        
        return averageEmbedding
    }

    func search(query: String) async -> Result<[SearchResult<VideoModel>], SearchError> {
        var searchQuery = query
        if let translationService = translationService {
            if case .success(let translated) = await translationService.translate(query, to: "en") {
                searchQuery = translated
            }
        }

        let queryEmbeddingResult = await embeddingService.generateTextEmbedding(from: searchQuery)

        guard case .success(let queryEmbedding) = queryEmbeddingResult else {
            if case .failure(let error) = queryEmbeddingResult {
                return .failure(.embeddingGenerationFailed(error))
            }
            return .failure(.unknown)
        }

        var results: [SearchResult<VideoModel>] = []
        
        for video in videos {
            guard let videoEmbedding = video.embedding else {
                continue
            }
            
            let similarity = embeddingService.calculateSimilarity(
                queryEmbedding,
                videoEmbedding
            )
            
            if similarity >= settings.values.searchSimilarityThreshold {
                results.append(SearchResult(item: video, similarity: similarity))
            }
        }
        
        results.sort { $0.similarity > $1.similarity }
        
        return .success(results)
    }

    func reset() {
        do {
            let groups = try context.fetch(FetchDescriptor<VideoGroupModel>())
            for group in groups {
                context.delete(group)
            }
            
            let videos = try context.fetch(FetchDescriptor<VideoModel>())
            for video in videos {
                context.delete(video)
            }
            
            try context.save()
        } catch {
            print("❌ Ошибка при сбросе контекста: \(error)")
        }
    }
}

enum VideoIndexingError: LocalizedError {
    case videoProcessingFailed
    case frameExtractionFailed
    case embeddingGenerationFailed
    
    var errorDescription: String? {
        switch self {
        case .videoProcessingFailed:
            return "Не удалось обработать видео"
        case .frameExtractionFailed:
            return "Не удалось извлечь кадры из видео"
        case .embeddingGenerationFailed:
            return "Не удалось сгенерировать эмбединги для видео"
        }
    }
}
