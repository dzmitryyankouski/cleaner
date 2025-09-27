import Foundation
import Photos
import UIKit

struct Photo {
    let index: Int
    let asset: PHAsset
    var embedding: [Float]
    var fileSize: Int64
    var isScreenshot: Bool
}

class PhotoService: ObservableObject {
    static let shared = PhotoService()
    
    @Published var photos: [Photo] = []
    @Published var indexed: Int = 0
    @Published var total: Int = 0
    @Published var groupsSimilar: [[Photo]] = []
    @Published var groupsDuplicates: [[Photo]] = []
    @Published var indexing: Bool = false

    @Published var similarPhotosPercent: Float = 0.85
    @Published var searchSimilarity: Float = 0.14
    @Published var selectedModel: String = "s0"

    @Published var itemsToRemove: Set<Int> = []
    @Published var itemsToRemoveFileSize: Int64 = 0
    
    private let imageEmbeddingService: ImageEmbeddingService
    private let clusterService: ClusterService
    private let translateService: TranslateService
    
    init() {
        self.imageEmbeddingService = ImageEmbeddingService()
        self.clusterService = ClusterService()
        self.translateService = TranslateService()
        
        Task {
            await loadAndIndexPhotos()
        }
    }
    
    func search(text: String) async -> [Photo] {
        let translatedText = await translateService.translate(text: text)
        let results = await imageEmbeddingService.findSimilarPhotos(query: translatedText, minSimilarity: searchSimilarity, photos: photos)
        return results.map { $0.0 }
    }
    
    func refreshPhotos() async {
        await MainActor.run {
            photos.removeAll()
            groupsSimilar.removeAll()
            groupsDuplicates.removeAll()
            itemsToRemove.removeAll()
            itemsToRemoveFileSize = 0
            indexed = 0
        }
        
        await loadAndIndexPhotos()
    }
    
    func switchModel(model: String) {
        selectedModel = model
        imageEmbeddingService.switchModel(model: model)
        print("🔄 Переключена модель на: \(model)")
    }
    
    func getGroupCount() -> Int {
        return groupsSimilar.count
    }
    
    func getTotalPhotosCount() -> Int {
        return photos.count
    }
    
    func getTotalFileSize() -> Int64 {
        return photos.reduce(0) { $0 + $1.fileSize }
    }

    func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    func getBluredPhotos() async -> [Photo] {
        let results = await imageEmbeddingService.findSimilarPhotos(query: "blured photo", minSimilarity: 0.21, photos: photos)

        return results.map { $0.0 }
    }

    func toggleShouldDelete(for photo: Photo) {
        if itemsToRemove.contains(photo.index) {
            itemsToRemove.remove(photo.index)
            itemsToRemoveFileSize -= photo.fileSize
        } else {
            itemsToRemoveFileSize += photo.fileSize
            itemsToRemove.insert(photo.index)
        }
    }

    private func getFileSize(for asset: PHAsset) async -> Int64 {
        return await withCheckedContinuation { continuation in
            let resources = PHAssetResource.assetResources(for: asset)
            if let resource = resources.first {
                if let fileSize = resource.value(forKey: "fileSize") as? Int64, fileSize > 0 {
                    print("💾 Размер файла (через ресурсы): \(fileSize)")
                    continuation.resume(returning: fileSize)
                    return
                }
            }
        }
    }

    private func loadAndIndexPhotos() async {
        // Запрашиваем разрешение на доступ к фото
        let status = PHPhotoLibrary.authorizationStatus()

        if (status == .denied || status == .restricted) {
            print("❌ Доступ к фототеке запрещен")
            return
        }

        let allPhotos = await loadPhotosFromLibrary()
        
        await MainActor.run {
            self.total = allPhotos.count
            self.indexing = true
        }

        await imageEmbeddingService.indexPhotos(assets: allPhotos, onItemCompleted: { [weak self] (index: Int, embedding: [Float]) -> Void in
            Task { @MainActor in
                guard let self = self else { return }

                let fileSize = await self.getFileSize(for: allPhotos[index])
                let isScreenshot = await self.isScreenshot(for: allPhotos[index])

                self.photos.append(Photo(index: index, asset: allPhotos[index], embedding: embedding, fileSize: fileSize, isScreenshot: isScreenshot))
                self.indexed += 1
            }
        })

        await createGroupsSimilar(for: self.photos.map { $0.embedding })
        await createGroupsDuplicates(for: self.photos)

        await MainActor.run {
            self.indexing = false
        }

        print("✅ Индексация завершена", self.indexing)
    }
    
    private func loadPhotosFromLibrary() async -> [PHAsset] {
        let fetchOptions = PHFetchOptions()
        let photos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        var assets: [PHAsset] = []
        photos.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
        return assets
    }
    
    private func createGroupsSimilar(for embeddings: [[Float]]) async {
        print("🔄 Создание групп фотографий", photos.count)
        guard !embeddings.isEmpty else { return }
        
        let groupIndices = await clusterService.getImageGroups(for: embeddings, threshold: similarPhotosPercent)

        print("🔄 Группы фотографий", groupIndices)
        
        // Конвертируем индексы в группы фото
        let photoGroups = groupIndices.map { indices in
            indices.compactMap { index in
                photos.indices.contains(index) ? photos[index] : nil
            }
        }.filter { !$0.isEmpty }
        
        // Сортируем группы по датам (от новых к старым)
        let sortedGroups = sortGroupsByDate(photoGroups)

        // вызываем toggleShouldDelete для каждого фото в группе кроме первого
        for group in sortedGroups {
            for (index, photo) in group.enumerated() {
                if index > 0 {
                    toggleShouldDelete(for: photo)
                }
            }
        }
        
        await MainActor.run {
            self.groupsSimilar = sortedGroups
            print("📁 Создано \(sortedGroups.count) групп фотографий, отсортированных по датам")
        }
    }

    private func createGroupsDuplicates(for photos: [Photo]) async {
        print("🔄 Создание групп дубликатов", photos.count)
        guard !photos.isEmpty else { return }
        
        let embeddings = photos.map { $0.embedding }
        let groupIndices = await clusterService.getImageGroups(for: embeddings, threshold: 0.99)

        print("🔄 Группы дубликатов", groupIndices)
        
        // Конвертируем индексы в группы фото
        let photoGroups = groupIndices.map { indices in
            indices.compactMap { index in
                photos.indices.contains(index) ? photos[index] : nil
            }
        }.filter { !$0.isEmpty }
        
        // Сортируем группы по датам (от новых к старым)
        let sortedGroups = sortGroupsByDate(photoGroups)
        
        await MainActor.run {
            self.groupsDuplicates = sortedGroups
            print("📁 Создано \(sortedGroups.count) групп дубликатов, отсортированных по датам")
        }
    }

    private func isScreenshot(for asset: PHAsset) async -> Bool {
        let mediaSubtypes = asset.mediaSubtypes

        if mediaSubtypes.contains(.photoScreenshot) {
            return true
        }
        
        return false
    }
    
    // MARK: - Group Sorting Methods
    private func getLatestPhotoInGroup(_ group: [Photo]) -> Photo? {
        return group.max { photo1, photo2 in
            guard let date1 = photo1.asset.creationDate,
                  let date2 = photo2.asset.creationDate else {
                return false
            }
            return date1 < date2
        }
    }
    
    private func sortGroupsByDate(_ groups: [[Photo]]) -> [[Photo]] {
        return groups.sorted { group1, group2 in
            guard let latestPhoto1 = getLatestPhotoInGroup(group1),
                  let latestPhoto2 = getLatestPhotoInGroup(group2),
                  let date1 = latestPhoto1.asset.creationDate,
                  let date2 = latestPhoto2.asset.creationDate else {
                return false
            }
            return date1 > date2 // Сортируем от новых к старым
        }
    }
}
