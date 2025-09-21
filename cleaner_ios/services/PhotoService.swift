import Foundation
import Photos
import UIKit

struct Photo {
    let asset: PHAsset
    var embedding: [Float]
    var fileSize: Int64
}

class PhotoService: ObservableObject {
    static let shared = PhotoService()
    
    // MARK: - Properties
    @Published var photos: [Photo] = []
    @Published var indexed: Int = 0
    @Published var total: Int = 0
    @Published var groups: [[Photo]] = []
    @Published var indexing: Bool = false
    
    private let imageEmbeddingService: ImageEmbeddingService
    private let clusterService: ClusterService
    private let translateService: TranslateService
    
    // MARK: - Initialization
    init() {
        self.imageEmbeddingService = ImageEmbeddingService()
        self.clusterService = ClusterService()
        self.translateService = TranslateService()
        
        // Загружаем и индексируем фото
        Task {
            await loadAndIndexPhotos()
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
        self.total = allPhotos.count

        self.indexing = true

        await imageEmbeddingService.indexPhotos(assets: allPhotos, onItemCompleted: { [weak self] (index: Int, embedding: [Float]) -> Void in
            Task { @MainActor in
                guard let self = self else { return }
                let fileSize = await self.getFileSize(for: allPhotos[index])
                self.photos.append(Photo(asset: allPhotos[index], embedding: embedding, fileSize: fileSize))
                self.indexed += 1
            }
        })

        await createGroups(for: self.photos.map { $0.embedding })

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
    
    private func createGroups(for embeddings: [[Float]]) async {
        print("🔄 Создание групп фотографий", photos.count)
        guard !embeddings.isEmpty else { return }
        
        let groupIndices = await clusterService.getImageGroups(for: embeddings, threshold: 0.85)

        print("🔄 Группы фотографий", groupIndices)
        
        // Конвертируем индексы в группы фото
        let photoGroups = groupIndices.map { indices in
            indices.compactMap { index in
                photos.indices.contains(index) ? photos[index] : nil
            }
        }.filter { !$0.isEmpty }
        
        await MainActor.run {
            self.groups = photoGroups
            print("📁 Создано \(photoGroups.count) групп фотографий")
        }
    }
    
    // MARK: - Public Methods
    func search(text: String) async -> [Photo] {
        let translatedText = await translateService.translate(text: text)
        let results = await imageEmbeddingService.findSimilarPhotos(query: translatedText, minSimilarity: 0.14, photos: photos)
        return results.map { $0.0 }
    }
    
    func refreshPhotos() async {
        photos.removeAll()
        groups.removeAll()
        indexed = 0
        
        await loadAndIndexPhotos()
    }
    
    func getPhotosInGroup(_ groupIndex: Int) -> [Photo] {
        guard groupIndex < groups.count else { return [] }
        return groups[groupIndex]
    }
    
    func getGroupCount() -> Int {
        return groups.count
    }
    
    func getTotalPhotosCount() -> Int {
        return photos.count
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
}
