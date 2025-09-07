import Foundation
import Photos
import UIKit

class SearchViewModel: ObservableObject {
    @Published var photos: [PHAsset] = []

    var clusterService = ClusterService()
    var imageEmbeddingService = ImageEmbeddingService()

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

        indexPhotos()
    }

    func searchImages() {
        // TODO: Реализовать поиск изображений
    }

    private func indexPhotos() {
        print("🔄 Начинаем индексацию \(photos.count) фотографий...")
        
        Task {
            do {
                // Конвертируем PHAsset в UIImage миниатюры
                let thumbnails = await convertAssetsToThumbnails(photos)
                print("✅ Создано \(thumbnails.count) миниатюр")
                
                // Генерируем эмбединги для миниатюр
                let embeddings = await imageEmbeddingService.generateEmbeddings(from: thumbnails)
                print("✅ Сгенерировано \(embeddings.count) эмбедингов")
                
                // Здесь можно сохранить эмбединги или передать их в ClusterService
                await MainActor.run {
                    print("🎉 Индексация завершена!")
                }
                
            } catch {
                print("❌ Ошибка при индексации: \(error)")
            }
        }
    }
    
    private func convertAssetsToThumbnails(_ assets: [PHAsset]) async -> [UIImage] {
        return await withTaskGroup(of: UIImage?.self) { group in
            var thumbnails: [UIImage] = []
            
            for asset in assets {
                group.addTask {
                    await self.convertAssetToThumbnail(asset)
                }
            }
            
            for await thumbnail in group {
                if let thumbnail = thumbnail {
                    thumbnails.append(thumbnail)
                }
            }
            
            return thumbnails
        }
    }
    
    private func convertAssetToThumbnail(_ asset: PHAsset) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let imageManager = PHImageManager.default()
            let requestOptions = PHImageRequestOptions()
            
            requestOptions.isSynchronous = false
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.resizeMode = .exact
            requestOptions.isNetworkAccessAllowed = false
            
            // Размер миниатюры для эмбедингов (можно настроить)
            let targetSize = CGSize(width: 224, height: 224)
            
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: requestOptions
            ) { image, info in
                continuation.resume(returning: image)
            }
        }
    }
}
