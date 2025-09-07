import Foundation
import Photos

class SearchViewModel: ObservableObject {
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
        let photos = PHAsset.fetchAssets(with: .image, options: nil)
        print("photos: \(photos)")
        print("Количество фотографий: \(photos.count)")
    }

    func searchImages() {
        // TODO: Реализовать поиск изображений
    }
}
