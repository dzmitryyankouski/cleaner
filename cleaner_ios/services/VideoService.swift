import Foundation
import Photos
import UIKit
import AVFoundation

struct Video {
    let asset: PHAsset
    let duration: TimeInterval
    let fileSize: Int64
    let creationDate: Date?
    let modificationDate: Date?
    let embedding: [Float]
}

class VideoService: ObservableObject {
    static let shared = VideoService()
    
    // MARK: - Properties
    @Published var videos: [Video] = []
    @Published var isLoading: Bool = false
    @Published var totalCount: Int = 0
    @Published var indexed: Int = 0
    @Published var indexing: Bool = false
    @Published var groupsSimilar: [[Video]] = []
    @Published var similarVideosPercent: Float = 0.93
    
    private var concurrentTasks = 5 // Количество параллельных потоков для индексации видео
    private let imageEmbeddingService = ImageEmbeddingService()
    private let clusterService = ClusterService()
    
    // MARK: - Initialization
    init() {
        Task {
            await loadVideosFromLibrary()
        }
    }
    
    // MARK: - Private Methods
    private func loadVideosFromLibrary() async {
        await MainActor.run {
            self.isLoading = true
            self.indexing = true
        }
        
        // Запрашиваем разрешение на доступ к фототеке
        let status = PHPhotoLibrary.authorizationStatus()
        
        if status == .denied || status == .restricted {
            print("❌ Доступ к фототеке запрещен")
            await MainActor.run {
                self.isLoading = false
                self.indexing = false
            }
            return
        }
        
        // Если разрешение не предоставлено, запрашиваем его
        if status == .notDetermined {
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            if newStatus == .denied || newStatus == .restricted {
                print("❌ Пользователь отказал в доступе к фототеке")
                await MainActor.run {
                    self.isLoading = false
                    self.indexing = false
                }
                return
            }
        }
        
        // Получаем все видео ассеты
        let assets = await fetchVideoAssets()
        
        await MainActor.run {
            self.totalCount = assets.count
            self.isLoading = false
            self.indexed = 0
        }
        
        // Параллельная индексация видео
        await indexVideos(assets: assets)
        
        // Создаем группы похожих видео
        await createGroupsSimilar(for: self.videos.map { $0.embedding })

        self.videos.sort { $0.fileSize > $1.fileSize }
        
        await MainActor.run {
            self.indexing = false
            print("✅ Индексация \(self.videos.count) видеофайлов завершена")
        }
    }
    
    private func fetchVideoAssets() async -> [PHAsset] {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        // Получаем только видеофайлы
        let videos = PHAsset.fetchAssets(with: .video, options: fetchOptions)
        
        // Конвертируем в массив для работы с async/await
        var assets: [PHAsset] = []
        videos.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
        return assets
    }
    
    /// Параллельная индексация видео с ограничением количества потоков
    private func indexVideos(assets: [PHAsset]) async {
        print("🔄 Начинаем индексацию \(assets.count) видеофайлов...")
        
        await withTaskGroup(of: (Int, Video?)?.self) { group in
            var activeTasks = 0
            
            for (index, asset) in assets.enumerated() {
                // Ждем, пока освободится место для новой таски
                while activeTasks >= concurrentTasks {
                    if let result = await group.next() {
                        if let (_, video) = result, let video = video {
                            await MainActor.run {
                                self.videos.append(video)
                                self.indexed += 1
                                print("✅ Проиндексировано \(self.indexed) из \(self.totalCount), всего потоков \(activeTasks)")
                            }
                        }
                        activeTasks -= 1
                    }
                }
                
                group.addTask {
                    let video = await self.processSingleVideo(asset, index: index)
                    return (index, video)
                }
                activeTasks += 1
            }
            
            // Обрабатываем оставшиеся результаты
            for await result in group {
                if let (_, video) = result, let video = video {
                    await MainActor.run {
                        self.videos.append(video)
                        self.indexed += 1
                        print("✅ Проиндексировано \(self.indexed) из \(self.totalCount)")
                    }
                }
            }
        }
    }
    
    /// Обрабатывает одно видео: получает размер файла и генерирует эмбеддинг
    private func processSingleVideo(_ asset: PHAsset, index: Int) async -> Video? {
        let fileSize = await getFileSize(for: asset)

        let embedding = await generateVideoEmbedding(for: asset)
        
        let video = Video(
            asset: asset,
            duration: asset.duration,
            fileSize: fileSize,
            creationDate: asset.creationDate,
            modificationDate: asset.modificationDate,
            embedding: embedding
        )
        
        return video
    }
    
    /// Генерирует эмбеддинг для видео, извлекая кадры каждую секунду
    private func generateVideoEmbedding(for asset: PHAsset) async -> [Float] {
        print("🎬 Начало генерации эмбеддинга для видео...")
        
        // Получаем AVAsset из PHAsset
        guard let avAsset = await getAVAsset(for: asset) else {
            print("❌ Не удалось получить AVAsset")
            return []
        }

        // Извлекаем кадры из видео (теперь параллельно)
        let frames = await extractFramesFromVideo(avAsset: avAsset, duration: asset.duration)
        
        guard !frames.isEmpty else {
            print("❌ Не удалось извлечь кадры из видео")
            return []
        }
        
        print("✅ Извлечено \(frames.count) кадров")
        
        // Генерируем эмбеддинги для каждого кадра последовательно
        // (параллелизм идёт на уровне видео, не кадров)
        var embeddings: [[Float]] = []
        for frame in frames {
            let embedding = await imageEmbeddingService.generateEmbedding(from: frame)
            if !embedding.isEmpty {
                embeddings.append(embedding)
            }
        }
        
        guard !embeddings.isEmpty else {
            print("❌ Не удалось сгенерировать эмбеддинги для кадров")
            return []
        }
        
        print("✅ Сгенерировано \(embeddings.count) эмбеддингов")
        
        // Вычисляем средний эмбеддинг
        let averageEmbedding = calculateAverageEmbedding(embeddings: embeddings)
        print("✅ Средний эмбеддинг вычислен, размер: \(averageEmbedding.count)")
        
        return averageEmbedding
    }
    
    /// Получает AVAsset из PHAsset
    private func getAVAsset(for asset: PHAsset) async -> AVAsset? {
        return await withCheckedContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = false
            
            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                continuation.resume(returning: avAsset)
            }
        }
    }
    
    private func extractFramesFromVideo(avAsset: AVAsset, duration: TimeInterval) async -> [CVPixelBuffer] {
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
            let time = CMTime(seconds: duration / 4.0, preferredTimescale: 600)
            times.append(time)
        }
        
        // Параллельная обработка кадров
        var frames: [CVPixelBuffer] = []
        
        await withTaskGroup(of: CVPixelBuffer?.self) { group in
            for time in times {
                group.addTask {
                    await self.extractFrame(generator: generator, at: time)
                }
            }
            
            for await pixelBuffer in group {
                if let pixelBuffer = pixelBuffer {
                    frames.append(pixelBuffer)
                }
            }
        }
        
        return frames
    }
    
    /// Извлекает один кадр в указанное время
    private func extractFrame(generator: AVAssetImageGenerator, at time: CMTime) async -> CVPixelBuffer? {
        return await withCheckedContinuation { continuation in
            generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, _, error in
                if let error = error {
                    print("❌ Ошибка извлечения кадра: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let cgImage = cgImage else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let pixelBuffer = self.cgImageToPixelBuffer(cgImage)
                continuation.resume(returning: pixelBuffer)
            }
        }
    }
    
    /// Преобразует CGImage в CVPixelBuffer (256x256 для MobileCLIP)
    private func cgImageToPixelBuffer(_ cgImage: CGImage) -> CVPixelBuffer? {
        let targetWidth = 256
        let targetHeight = 256
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            targetWidth,
            targetHeight,
            kCVPixelFormatType_32ARGB,
            nil,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        defer { CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0)) }
        
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: pixelData,
            width: targetWidth,
            height: targetHeight,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))
        
        return buffer
    }
    
    /// Вычисляет средний эмбеддинг из массива эмбеддингов
    private func calculateAverageEmbedding(embeddings: [[Float]]) -> [Float] {
        guard !embeddings.isEmpty else { return [] }
        
        let embeddingSize = embeddings[0].count
        var averageEmbedding = [Float](repeating: 0, count: embeddingSize)
        
        // Суммируем все эмбеддинги
        for embedding in embeddings {
            for i in 0..<embeddingSize {
                averageEmbedding[i] += embedding[i]
            }
        }
        
        // Делим на количество эмбеддингов для получения среднего
        let count = Float(embeddings.count)
        for i in 0..<embeddingSize {
            averageEmbedding[i] /= count
        }
        
        return averageEmbedding
    }
    
    private func getFileSize(for asset: PHAsset) async -> Int64 {
        return await withCheckedContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = false
            
            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                if let urlAsset = avAsset as? AVURLAsset {
                    do {
                        let resourceValues = try urlAsset.url.resourceValues(forKeys: [.fileSizeKey])
                        let fileSize = Int64(resourceValues.fileSize ?? 0)
                        continuation.resume(returning: fileSize)
                    } catch {
                        print("❌ Ошибка получения размера файла: \(error)")
                        continuation.resume(returning: 0)
                    }
                } else {
                    continuation.resume(returning: 0)
                }
            }
        }
    }
    
    // MARK: - Grouping Methods
    
    /// Создает группы похожих видео
    private func createGroupsSimilar(for embeddings: [[Float]]) async {
        print("🔄 Создание групп похожих видео", videos.count)
        guard !embeddings.isEmpty else { return }
        
        // Фильтруем видео с валидными эмбеддингами (непустыми и одинаковой размерности)
        var validVideos: [Video] = []
        var validEmbeddings: [[Float]] = []
        
        // Находим стандартную размерность (от первого непустого эмбеддинга)
        guard let firstValidEmbedding = embeddings.first(where: { !$0.isEmpty }) else {
            print("⚠️ Нет валидных эмбеддингов для видео")
            return
        }
        let standardDim = firstValidEmbedding.count
        
        for (index, embedding) in embeddings.enumerated() {
            if !embedding.isEmpty && embedding.count == standardDim {
                validVideos.append(videos[index])
                validEmbeddings.append(embedding)
            } else {
                if embedding.isEmpty {
                    print("⚠️ Видео \(index) имеет пустой эмбеддинг, пропускаем")
                } else {
                    print("⚠️ Видео \(index) имеет неверную размерность эмбеддинга: \(embedding.count) вместо \(standardDim), пропускаем")
                }
            }
        }
        
        print("✅ Валидных видео для кластеризации: \(validVideos.count) из \(videos.count)")
        
        guard validEmbeddings.count > 1 else {
            print("⚠️ Недостаточно валидных видео для создания групп")
            return
        }
        
        let groupIndices = await clusterService.getImageGroups(for: validEmbeddings, threshold: similarVideosPercent)
        
        print("🔄 Группы похожих видео", groupIndices)
        
        // Конвертируем индексы в группы видео (используем validVideos вместо videos)
        let videoGroups = groupIndices.map { indices in
            indices.compactMap { index in
                validVideos.indices.contains(index) ? validVideos[index] : nil
            }
        }.filter { $0.count > 1 } // Оставляем только группы с 2+ видео
        
        // Сортируем группы по датам (от новых к старым)
        let sortedGroups = sortGroupsByDate(videoGroups)
        
        await MainActor.run {
            self.groupsSimilar = sortedGroups
            print("📁 Создано \(sortedGroups.count) групп похожих видео, отсортированных по датам")
        }
    }
    
    // MARK: - Group Sorting Methods
    
    /// Находит самое новое видео в группе
    private func getLatestVideoInGroup(_ group: [Video]) -> Video? {
        return group.max { video1, video2 in
            guard let date1 = video1.asset.creationDate,
                  let date2 = video2.asset.creationDate else {
                return false
            }
            return date1 < date2
        }
    }
    
    /// Сортирует группы видео по дате (от новых к старым)
    private func sortGroupsByDate(_ groups: [[Video]]) -> [[Video]] {
        return groups.sorted { group1, group2 in
            guard let latestVideo1 = getLatestVideoInGroup(group1),
                  let latestVideo2 = getLatestVideoInGroup(group2),
                  let date1 = latestVideo1.asset.creationDate,
                  let date2 = latestVideo2.asset.creationDate else {
                return false
            }
            return date1 > date2 // Сортируем от новых к старым
        }
    }
    
    // MARK: - Public Methods
    func refreshVideos() async {
        self.videos.removeAll()
        self.groupsSimilar.removeAll()
        self.indexed = 0
        
        await loadVideosFromLibrary()
    }
    
    func getVideosCount() -> Int {
        return videos.count
    }
    
    func getGroupCount() -> Int {
        return groupsSimilar.count
    }
    
    func getTotalFileSize() -> Int64 {
        return videos.reduce(0) { $0 + $1.fileSize }
    }
    
    func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
