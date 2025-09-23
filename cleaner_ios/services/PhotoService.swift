import Foundation
import Photos
import UIKit

struct Photo {
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
        photos.removeAll()
        groupsSimilar.removeAll()
        groupsDuplicates.removeAll()
        indexed = 0
        
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

    private func getFileSize(for asset: PHAsset) async -> Int64 {
        let options = PHImageRequestOptions()

        options.isSynchronous = true
        options.deliveryMode = .fastFormat
        options.resizeMode = .none
        
        var fileSize: Int64 = 0
        
        PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
            if let data = data {
                fileSize = Int64(data.count)
            }
        }
        
        print("💾 Размер файла: \(fileSize)")

        return fileSize
    }

    private func loadAndIndexPhotos() async {
        // Запрашиваем разрешение на доступ к фото
        let status = PHPhotoLibrary.authorizationStatus()

        if (status == .denied || status == .restricted) {
            print("❌ Доступ к фототеке запрещен")
            return
        }

        let allPhotos = await loadPhotosFromLibrary()
        self.total = allPhotos.count

        self.indexing = true

        await imageEmbeddingService.indexPhotos(assets: allPhotos, onItemCompleted: { [weak self] (index: Int, embedding: [Float]) -> Void in
            Task { @MainActor in
                guard let self = self else { return }

                let fileSize = await self.getFileSize(for: allPhotos[index])
                let isScreenshot = await self.isScreenshot(for: allPhotos[index])

                self.photos.append(Photo(asset: allPhotos[index], embedding: embedding, fileSize: fileSize, isScreenshot: isScreenshot))
                self.indexed += 1
            }
        })

        await createGroupsSimilar(for: self.photos.map { $0.embedding })
        await createGroupsDuplicates(for: self.photos)

        self.indexing = false

        print("✅ Индексация завершена", self.indexing)
    }
    
    private func loadPhotosFromLibrary() async -> [PHAsset] {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
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
        
        await MainActor.run {
            self.groupsSimilar = photoGroups
            print("📁 Создано \(photoGroups.count) групп фотографий")
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
        
        await MainActor.run {
            self.groupsDuplicates = photoGroups
            print("📁 Создано \(photoGroups.count) групп дубликатов")
        }
    }

    private func isScreenshot(for asset: PHAsset) async -> Bool {
        let mediaSubtypes = asset.mediaSubtypes

        if mediaSubtypes.contains(.photoScreenshot) {
            return true
        }
        
        return false
    }
}
