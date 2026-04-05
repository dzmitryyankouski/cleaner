import Foundation
import Observation
import SwiftData
import Photos
import Combine
import UIKit

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

    var selectedPhotos: [String: PhotoModel] = [:]

    var selectedSort: SortPhoto = .date {
        didSet {
            Task {
                await self.refresh()
            }
        }
    }
    var selectedFilter: Set<FilterPhoto> = [] {
        didSet {
            Task {
                await self.refresh()
            }
        }
    }

    private let selectedSortSubject = CurrentValueSubject<SortPhoto, Never>(.date)
    private let selectedFilterSubject = CurrentValueSubject<Set<FilterPhoto>, Never>([])
    
    private let photoAssetRepository: PhotoRepositoryProtocol
    private let embeddingService: EmbeddingServiceProtocol
    private let clusteringService: ClusteringServiceProtocol
    private let translationService: TranslationServiceProtocol?
    private let concurrentTasks = 10
    private let context: ModelContext
    private let settings: Settings

    private static let blurryTextSimilarityThreshold: Float = 0.20

    init(
        photoAssetRepository: PhotoRepositoryProtocol,
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

        let photosResult = await photoAssetRepository.fetchAll(filter: selectedFilter, sort: selectedSort)
        guard case .success(let photos) = photosResult else {
            print("❌ Не удалось загрузить фотографии")
            return
        }

        total = photos.count
        
        await indexPhotos()
        await regroup()
        await refresh()

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
    }

    func refresh() async {
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

    func delete(photos: [PhotoModel]) async -> Result<Void, AssetError> {
        let result = await photoAssetRepository.delete(photos: photos)

        guard case .success = result else {
            return .failure(.loadingFailed)
        }

        await regroup()
        await refresh()
        return .success(())
    }

    func removeLive(photos: [PhotoModel]) async -> Result<Void, AssetError> {
        print("🔍 Удаляем живое фото: \(photos.count)")
        await withTaskGroup(of: Void.self) { group in
            for photo in photos {
                group.addTask {
                    let result = await self.photoAssetRepository.removeLive(photo: photo)
                    guard case .success = result else {
                        print("❌ Не удалось удалить живое фото: \(photo.id)")
                        return
                    }

                    print("✅ Живое фото удалено: \(photo.id)")
                }
            }
        }

        await refresh()
        return .success(())
    }

    func compress(photos: [PhotoModel]) async -> Result<Void, AssetError> {
        await withTaskGroup(of: Void.self) { group in
            for photo in photos {
                group.addTask {
                    let result = await self.photoAssetRepository.compress(photo: photo, quality: 0.7)
                    guard case .success(let newPhoto) = result else {
                        print("❌ Не удалось сжать фото: \(photo.id)")
                        return
                    }

                    let oldFileSize = FileSize(bytes: photo.fileSize ?? 0).formatted
                    let newFileSize = FileSize(bytes: newPhoto.fileSize ?? 0).formatted
                    
                    let oldSize = Double(photo.fileSize ?? 0)
                    let newSize = Double(newPhoto.fileSize ?? 0)
                    let compressionPercent = oldSize > 0 ? ((oldSize - newSize) / oldSize) * 100 : 0.0

                    print("Photo compressed from \(oldFileSize) to \(newFileSize) (\(String(format: "%.1f", compressionPercent))%)")
                }
            }
        }

        await photoAssetRepository.delete(photos: photos)
        await refresh()

        return .success(())
    }

    func select(photo: PhotoModel) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        if selectedPhotos[photo.id] != nil {
            selectedPhotos.removeValue(forKey: photo.id)
        } else {
            selectedPhotos[photo.id] = photo
        }
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

        var blurryTextEmbedding: [Float]? = nil
        let blurryEmbeddingResult = await embeddingService.generateTextEmbedding(from: "blur photo where the subject is out of focus")

        if case .success(let embedding) = blurryEmbeddingResult {
            blurryTextEmbedding = embedding
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
                    let blurryRef = blurryTextEmbedding

                    let assets = PHAsset.fetchAssets(withLocalIdentifiers: [photoId], options: nil)
                    guard let asset = assets.firstObject else { return }

                    async let fileSizeAsync = self.photoAssetRepository.getFileSize(for: asset)
                    async let embeddingAsync = self.embeddingService.generateEmbeddingFromAsset(asset)

                    let (fileSize, embedding) = await (fileSizeAsync, embeddingAsync)

                    let isModified = self.photoAssetRepository.isModified(for: asset)
                    let isFavorite = self.photoAssetRepository.isFavorite(for: asset)

                    if case .success(let fileSize) = fileSize, case .success(let embedding) = embedding {
                        let isBlurry = blurryRef.map { blurry in
                            self.embeddingService.calculateSimilarity(blurry, embedding) >= Self.blurryTextSimilarityThreshold
                        } ?? false

                        await MainActor.run {
                            photo.embedding = embedding
                            photo.isScreenshot = asset.mediaSubtypes.contains(.photoScreenshot)
                            photo.isModified = isModified
                            photo.fileSize = fileSize
                            photo.isFavorite = isFavorite
                            photo.isBlurry = isBlurry
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
