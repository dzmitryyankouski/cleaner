import Foundation
import Photos
import SwiftUI

@MainActor
class PhotosViewModel: ObservableObject {
    @Published var photos: [PHAsset] = []
    @Published var groups: [[Int]] = []
    @Published var isIndexing = false
    @Published var processedPhotosCount = 0

    var imageEmbeddingService = ImageEmbeddingService()
    var clusterService = ClusterService()
    var embeddings: [[Float]] = []

    init() {
        imageEmbeddingService.onPhotoProcessed = { [weak self] photo in
            DispatchQueue.main.async {
                self?.processedPhotosCount = self?.imageEmbeddingService.processedPhotos.count ?? 0
                self?.embeddings.append(photo.embedding)
            }
        }
        
        Task {
            await startProcessing()
        }
    }
    
    private func startProcessing() async {
        await loadPhotos()
        await indexPhotos()
        await group()
    }

    private func loadPhotos() async {
        let fetchResult = PHAsset.fetchAssets(with: .image, options: nil)
        var assets: [PHAsset] = []
        
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
        self.photos = assets
    }
    

    private func indexPhotos() async {
        isIndexing = true
        await imageEmbeddingService.indexPhotos(photos: photos)
    }

    private func group() async {
        groups = await clusterService.getImageGroups(for: embeddings, threshold: 0.85)
        print("🔄 Группировка завершена! Найдено \(groups.count) групп", groups)
        isIndexing = false
    }
}
