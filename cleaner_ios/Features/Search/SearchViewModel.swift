import Foundation
import Photos

class SearchViewModel: ObservableObject {
    @Published var photos: [PHAsset] = []

    var clusterService = ClusterService()

    init() {
        print("SearchViewModel init")
        requestPhotoLibraryAccess()
    }
    
    private func requestPhotoLibraryAccess() {
        let currentStatus = PHPhotoLibrary.authorizationStatus()

        if currentStatus == .authorized || currentStatus == .limited {
            loadPhotos()
        }

        if currentStatus == .notDetermined {
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    if status == .authorized || status == .limited {
                        self.loadPhotos()
                    }
                }
            }
        }
    }
    
    private func loadPhotos() {
        let fetchResult = PHAsset.fetchAssets(with: .image, options: nil)
        var assets: [PHAsset] = []
        
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
        self.photos = assets
    }

    func searchImages() {
        // TODO: Реализовать поиск изображений
    }
}
