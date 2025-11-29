import Foundation
import Observation
import SwiftData
import Photos

@Observable
class PhotoLibrary {
    var indexing: Bool = false
    var indexed: Int = 0
    var total: Int = 0
    
    var similarGroups: [PhotoGroupModel] = []
    var similarPhotos: [PhotoModel] = []
    var similarPhotosFileSize: Int64 = 0

    var duplicatesGroups: [PhotoGroupModel] = []
    var duplicatesPhotos: [PhotoModel] = []
    var duplicatesPhotosFileSize: Int64 = 0

    var screenshots: [PhotoModel] = []
    var screenshotsFileSize: Int64 = 0

    var photos: [PhotoModel] = []
    var photosFileSize: Int64 = 0

    private let photoAssetRepository: AssetRepositoryProtocol
    private let embeddingService: EmbeddingServiceProtocol
    private let clusteringService: ClusteringServiceProtocol
    private let translationService: TranslationServiceProtocol?
    private let concurrentTasks = 10
    private let context: ModelContext
    private let settings: Settings

    init(
        photoAssetRepository: AssetRepositoryProtocol,
        embeddingService: EmbeddingServiceProtocol,
        clusteringService: ClusteringServiceProtocol,
        translationService: TranslationServiceProtocol? = nil,
        settings: Settings,
        modelContext: ModelContext
    ) {
        self.photoAssetRepository = photoAssetRepository
        self.embeddingService = embeddingService
        self.clusteringService = clusteringService
        self.translationService = translationService
        self.context = modelContext
        self.settings = settings

        Task {
            await loadPhotos()
        }
    }

    func loadPhotos() async {
        print("🔍 Загрузка фотографий")
        indexing = true

        photos = await getAllPhotos()
        total = photos.count
        
        await indexPhotos()

        photosFileSize = photos.reduce(0) { $0 + ($1.fileSize ?? 0) }

        screenshots = getScreenshots()
        screenshotsFileSize = screenshots.reduce(0) { $0 + ($1.fileSize ?? 0) }

        await regroup()

        indexing = false

        print("✅ Фотографии загружены")
    }

    func reset() {
        do {
            let groups = try context.fetch(FetchDescriptor<PhotoGroupModel>())
            for group in groups {
                context.delete(group)
            }
            
            let photos = try context.fetch(FetchDescriptor<PhotoModel>())
            for photo in photos {
                context.delete(photo)
            }
            
            try context.save()
        } catch {
            print("❌ Ошибка при сбросе контекста: \(error)")
        }

        similarGroups = []
        similarPhotos = []
        similarPhotosFileSize = 0

        duplicatesGroups = []
        duplicatesPhotos = []
        duplicatesPhotosFileSize = 0

        screenshots = []
        screenshotsFileSize = 0

        photos = []

        total = 0
        indexed = 0
    }

    func regroup() async {
        let threshold = settings.values.photoSimilarityThreshold
        await groupSimilar(threshold: threshold)
        await groupDuplicates(threshold: 0.99)

        similarGroups = getSimilarGroups()
        similarPhotos = getSimilarPhotos()
        similarPhotosFileSize = similarPhotos.reduce(0) { $0 + ($1.fileSize ?? 0) }

        duplicatesGroups = getDuplicatesGroups()
        duplicatesPhotos = getDuplicatesPhotos()
        duplicatesPhotosFileSize = duplicatesPhotos.reduce(0) { $0 + ($1.fileSize ?? 0) }
    }

    func search(query: String) async -> Result<[SearchResult<PhotoModel>], SearchError> {
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

        var results: [SearchResult<PhotoModel>] = []
        
        for photo in photos {
            guard let photoEmbedding = photo.embedding else {
                continue
            }
            
            let similarity = embeddingService.calculateSimilarity(
                queryEmbedding,
                photoEmbedding
            )
            
            if similarity >= settings.values.searchSimilarityThreshold {
                results.append(SearchResult(item: photo, similarity: similarity))
            }
        }
        
        results.sort { $0.similarity > $1.similarity }
        
        return .success(results)
    }

    private func getAllPhotos() async -> [PhotoModel] {
        let assets = await photoAssetRepository.fetchAssets()

        guard case .success(let assets) = assets else {
            print("❌ Не удалось загрузить фотографии")
            return []
        }

        for asset in assets {
            let assetId = asset.localIdentifier
            if let _ = try? context.fetch(FetchDescriptor<PhotoModel>(predicate: #Predicate<PhotoModel> { $0.id == assetId })).first {
                continue
            }
            
            let photo = PhotoModel(asset: asset)
            context.insert(photo)
        }

        do {
            try context.save()
        } catch {
            print("❌ Ошибка при сохранении фотографий: \(error)")
            return []
        }
        
        return (try? context.fetch(FetchDescriptor<PhotoModel>())) ?? []
    }

    private func indexPhotos() async {
        guard let photosToIndex = try? context.fetch(FetchDescriptor<PhotoModel>(predicate: #Predicate<PhotoModel> { $0.embedding == nil })) else {
            print("❌ Нет фото для индексации")
            return
        }

        // guard let photos = try? context.fetch(FetchDescriptor<PhotoModel>()) else {
        //     print("❌ Нет фото для индексации")
        //     return
        // }
        
        await withTaskGroup(of: Void.self) { group in
            var activeTasks = 0
            
            for photo in photosToIndex {
                while activeTasks >= concurrentTasks {
                    await group.next()
                    activeTasks -= 1
                }

                group.addTask { [weak self] in
                    guard let self = self else { return }
                    let photoId = photo.id

                    let assets = PHAsset.fetchAssets(withLocalIdentifiers: [photoId], options: nil)
                    guard let asset = assets.firstObject else { return }

                    async let fileSizeAsync = self.photoAssetRepository.getFileSize(for: asset)
                    async let embeddingAsync = self.embeddingService.generateEmbeddingFromAsset(asset)

                    let (fileSize, embedding) = await (fileSizeAsync, embeddingAsync)

                    if case .success(let fileSize) = fileSize, case .success(let embedding) = embedding {
                        await MainActor.run {
                            photo.embedding = embedding
                            photo.isScreenshot = asset.mediaSubtypes.contains(.photoScreenshot)
                            photo.fileSize = fileSize
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
            print("Saving context")
            try context.save()
        } catch {
            print("❌ Ошибка при сохранении контекста: \(error)")
        }
    }

    private func getSimilarGroups() -> [PhotoGroupModel] {
        return (try? context.fetch(PhotoGroupModel.similar)) ?? []
    }

    private func getSimilarPhotos() -> [PhotoModel] {
        return (try? context.fetch(PhotoModel.similar)) ?? []
    }

    private func getDuplicatesGroups() -> [PhotoGroupModel] {
        return (try? context.fetch(PhotoGroupModel.duplicates)) ?? []
    }

    private func getDuplicatesPhotos() -> [PhotoModel] {
        return (try? context.fetch(PhotoModel.duplicates)) ?? []
    }

    private func getScreenshots() -> [PhotoModel] {
        return (try? context.fetch(PhotoModel.screenshots)) ?? []
    }

    private func groupSimilar(threshold: Float) async {
        let groups = getSimilarGroups()

        for group in groups {
            context.delete(group)
        }

        await group(type: "similar", threshold: threshold)
    }

    private func groupDuplicates(threshold: Float) async {
        let groups = getDuplicatesGroups()

        for group in groups {
            context.delete(group)
        }

        await group(type: "duplicates", threshold: threshold)
    }
    
    private func group(type: String, threshold: Float) async {
        guard let photos = try? context.fetch(FetchDescriptor<PhotoModel>()) else {
            print("❌ Нет фото для группировки")
            return
        }

        print("🔍 Фото для группировки: \(photos.count)")
        
        guard photos.count > 1 else { return }

        print("Начинаем группировку фотографий")
        
        let embeddings = photos.compactMap { $0.embedding }
        let groupIndices = await clusteringService.groupEmbeddings(embeddings, threshold: threshold)

        print("🔍 Эмбединги: \(embeddings.count)")

        for indices in groupIndices {
            let groupPhotos = indices.compactMap { validIndex -> PhotoModel? in
                guard photos.indices.contains(validIndex) else { return nil }
                return photos[validIndex]
            }
            
            guard groupPhotos.count > 1 else { continue }
            
            let groupId = UUID().uuidString
            let group = PhotoGroupModel(id: groupId, type: type)
            
            // Устанавливаем связь многие-ко-многим с обеих сторон
            group.photos = groupPhotos

            for photo in groupPhotos {
                if !photo.groups.contains(where: { $0.id == group.id }) {
                    photo.groups.append(group)
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
}

struct SearchResult<T> {
    let item: T
    let similarity: Float
    
    init(item: T, similarity: Float) {
        self.item = item
        self.similarity = similarity
    }
}

enum SearchError: LocalizedError {
    case embeddingGenerationFailed(EmbeddingError)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .embeddingGenerationFailed(let error):
            return "Не удалось сгенерировать эмбединг: \(error.localizedDescription)"
        case .unknown:
            return "Неизвестная ошибка"
        }
    }
}
