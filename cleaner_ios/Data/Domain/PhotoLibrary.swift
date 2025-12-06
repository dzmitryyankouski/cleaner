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
    var similarPhotosFileSize: Int64 = 0
    var similarPhotosCount: Int = 0

    var duplicatesGroups: [PhotoGroupModel] = []
    var duplicatesPhotosFileSize: Int64 = 0
    var duplicatesPhotosCount: Int = 0

    var photos: [PhotoModel] = []
    var photosFileSize: Int64 = 0

    var selectedSort: SortPhoto = .date
    var selectedFilter: Set<FilterPhoto> = []

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
        await regroup()

        indexing = false

        print("✅ Фотографии загружены")
    }

    func reset() async {
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
        similarPhotosFileSize = 0

        duplicatesGroups = []
        duplicatesPhotosFileSize = 0

        photos = []

        total = 0
        indexed = 0

        await loadPhotos()
    }

    func regroup() async {
        let threshold = settings.values.photoSimilarityThreshold
        await groupSimilar(threshold: threshold)
        await groupDuplicates(threshold: 0.99)

        similarGroups = getSimilarGroups()
        similarPhotosFileSize = similarGroups.reduce(0) { $0 + ($1.totalSize ?? 0) }
        similarPhotosCount = similarGroups.reduce(0) { $0 + ($1.photos.count ?? 0) }

        duplicatesGroups = getDuplicatesGroups()
        duplicatesPhotosFileSize = duplicatesGroups.reduce(0) { $0 + ($1.totalSize ?? 0) }
        duplicatesPhotosCount = duplicatesGroups.reduce(0) { $0 + ($1.photos.count ?? 0) }
    }

    func filter() async {
        photos = (try? context.fetch(PhotoModel.apply(filter: selectedFilter, sort: selectedSort))) ?? []
        photosFileSize = photos.reduce(0) { $0 + ($1.fileSize ?? 0) }

        similarGroups = getSimilarGroups()
        similarPhotosFileSize = similarGroups.reduce(0) { $0 + ($1.totalSize ?? 0) }
        similarPhotosCount = similarGroups.reduce(0) { $0 + ($1.photos.count ?? 0) }

        duplicatesGroups = getDuplicatesGroups()
        duplicatesPhotosFileSize = duplicatesGroups.reduce(0) { $0 + ($1.totalSize ?? 0) }
        duplicatesPhotosCount = duplicatesGroups.reduce(0) { $0 + ($1.photos.count ?? 0) }
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

    func delete(photo: PhotoModel) async {
        context.delete(photo)
        print("🔍 Удаляем фотографию: \(photo.id)")

        do {
            try context.save()
        } catch {
            print("❌ Ошибка при сохранении контекста: \(error)")
        }

        await filter()
    }

    func removeLive(photo: PhotoModel) async {
        print("🔍 Удаляем live фотографию: \(photo.id)")
    }

    func compress(photo: PhotoModel) async {
        print("🔍 Сжимаем фотографию: \(photo.id)")
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
        
        return (try? context.fetch(PhotoModel.apply(filter: selectedFilter, sort: selectedSort))) ?? []
    }

    private func indexPhotos() async {
        if let indexedPhotos = try? context.fetch(FetchDescriptor<PhotoModel>(predicate: #Predicate<PhotoModel> { $0.embedding != nil })) {
            await MainActor.run {
                indexed = indexedPhotos.count
            }
        }

        guard let photosToIndex = try? context.fetch(FetchDescriptor<PhotoModel>(predicate: #Predicate<PhotoModel> { $0.embedding == nil })) else {
            print("❌ Нет фото для индексации")
            return
        }
        
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

                    let isModified = self.photoAssetRepository.isModified(for: asset)
                    let isFavorite = self.photoAssetRepository.isFavorite(for: asset)

                    if case .success(let fileSize) = fileSize, case .success(let embedding) = embedding {
                        await MainActor.run {
                            photo.embedding = embedding
                            photo.isScreenshot = asset.mediaSubtypes.contains(.photoScreenshot)
                            photo.isModified = isModified
                            photo.fileSize = fileSize
                            photo.isFavorite = isFavorite
                            self.indexed += 1

                            do {
                                try self.context.save()
                            } catch {
                                print("❌ Ошибка при сохранении контекста: \(error)")
                            }
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

        let photos = try? context.fetch(PhotoModel.apply(filter: selectedFilter, sort: selectedSort))
        photosFileSize = (photos ?? []).reduce(0) { $0 + ($1.fileSize ?? 0) }
    }

    private func getSimilarGroups() -> [PhotoGroupModel] {
        return (try? context.fetch(PhotoGroupModel.apply(filter: selectedFilter, sort: selectedSort, type: "similar"))) ?? []
    }

    private func getDuplicatesGroups() -> [PhotoGroupModel] {
        return (try? context.fetch(PhotoGroupModel.apply(filter: selectedFilter, sort: selectedSort, type: "duplicates"))) ?? []
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
            group.updateTotalSize()
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
