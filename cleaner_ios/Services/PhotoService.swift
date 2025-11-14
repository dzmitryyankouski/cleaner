import SwiftData
import Photos

final class PhotoService {
    private let photoAssetRepository: AssetRepositoryProtocol
    private let embeddingService: EmbeddingServiceProtocol
    private let clusteringService: ClusteringServiceProtocol
    private let concurrentTasks = 10
    private let context: ModelContext

    init(
        photoAssetRepository: AssetRepositoryProtocol,
        embeddingService: EmbeddingServiceProtocol,
        clusteringService: ClusteringServiceProtocol
    ) {
        self.photoAssetRepository = photoAssetRepository
        self.embeddingService = embeddingService
        self.clusteringService = clusteringService

        do {
            let container = try ModelContainer(for: PhotoModel.self, PhotoGroupModel.self)
            self.context = ModelContext(container)
        } catch {
            fatalError("❌ Не удалось создать контекст для PhotoModel: \(error)")
        }
    }

    func getSimilarGroups() -> [PhotoGroupModel] {
        return (try? context.fetch(PhotoGroupModel.similar)) ?? []
    }

    func getSimilarPhotos() -> [PhotoModel] {
        return (try? context.fetch(PhotoModel.similar)) ?? []
    }

    func getAllPhotos() async -> [PhotoModel] {
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

    func indexPhotos(onProgress: (() -> Void)? = nil) async {
        guard let photos = try? context.fetch(FetchDescriptor<PhotoModel>(predicate: #Predicate<PhotoModel> { $0.embedding == nil })) else {
            print("❌ Нет фото для индексации")
            return
        }

        //  guard let photos = try? context.fetch(FetchDescriptor<PhotoModel>()) else {
        //     print("❌ Нет фото для индексации")
        //     return
        // }
        
        await withTaskGroup(of: Void.self) { group in
            var activeTasks = 0
            
            for photo in photos {
                while activeTasks >= concurrentTasks {
                    await group.next()
                    activeTasks -= 1
                }

                group.addTask { [weak self] in
                    guard let self = self else { return }
                    let photoId = photo.id
                    guard let asset = photo.asset else { return }
                    
                    let embedding = await self.embeddingService.generateEmbeddingFromAsset(asset)

                    if case .success(let embedding) = embedding {
                        await MainActor.run {
                            photo.embedding = embedding
                            onProgress?()
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
    
    func groupSimilar(threshold: Float) async {

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
        
        var groupsWithPhotos: [(PhotoGroupModel, [PhotoModel])] = []

        for indices in groupIndices {
            let groupPhotos = indices.compactMap { validIndex -> PhotoModel? in
                guard photos.indices.contains(validIndex) else { return nil }
                return photos[validIndex]
            }
            
            guard groupPhotos.count > 1 else { continue }
            
            let groupId = UUID().uuidString
            let group = PhotoGroupModel(id: groupId, type: "similar")
            group.photos = groupPhotos
            group.updateLatestDate()
            context.insert(group)
        }
    }
}
