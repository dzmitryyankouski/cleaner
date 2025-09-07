import Foundation
import Photos
import UIKit

class SearchViewModel: ObservableObject {
    @Published var photos: [PHAsset] = []
    @Published var processedPhotosCount = 0
    @Published var isIndexing = false

    var clusterService = ClusterService()
    var imageEmbeddingService = ImageEmbeddingService()

    init() {
        print("SearchViewModel init")

        Task {
            let status = await requestPhotoLibraryAccess()

            if status == .authorized || status == .limited {
                await loadPhotos()
                await indexPhotos()
            }
        }

        imageEmbeddingService.onPhotoProcessed = { [weak self] photo in
            DispatchQueue.main.async {
                self?.processedPhotosCount = self?.imageEmbeddingService.processedPhotos.count ?? 0
            }
        }
    }
    
    private func requestPhotoLibraryAccess() async -> PHAuthorizationStatus {
        let currentStatus = PHPhotoLibrary.authorizationStatus()

        if currentStatus == .notDetermined {
            await PHPhotoLibrary.requestAuthorization(for: .readWrite)

            let newStatus = PHPhotoLibrary.authorizationStatus()

            if newStatus == .authorized || newStatus == .limited {
                return newStatus
            }
        }

        return currentStatus
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
        isIndexing = false
    }

    func searchImages() {
        // TODO: Реализовать поиск изображений
    }
}
