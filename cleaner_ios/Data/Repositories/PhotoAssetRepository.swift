import Foundation
import Photos

// MARK: - Photo Asset Repository

/// Репозиторий для работы с фото ассетами из библиотеки
final class PhotoAssetRepository: AssetRepositoryProtocol {
    
    // MARK: - Public Methods
    
    /// Загружает все фото из библиотеки
    func fetchAssets() async -> Result<[PHAsset], AssetError> {
        // Проверяем права доступа
        let authStatus = PHPhotoLibrary.authorizationStatus()
        
        if authStatus == .denied || authStatus == .restricted {
            return .failure(.permissionDenied)
        }
        
        if authStatus == .notDetermined {
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            if newStatus == .denied || newStatus == .restricted {
                return .failure(.permissionDenied)
            }
        }
        
        // Загружаем фото
        let fetchOptions = PHFetchOptions()
        let photos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        var assets: [PHAsset] = []
        photos.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
        return .success(assets)
    }
    
    func getFileSize(for asset: PHAsset) async -> Result<Int64, AssetError> {
        return await withCheckedContinuation { continuation in
            let resources = PHAssetResource.assetResources(for: asset)
            
            if let resource = resources.first,
               let fileSize = resource.value(forKey: "fileSize") as? Int64,
               fileSize > 0 {
                continuation.resume(returning: .success(fileSize))
            } else {
                continuation.resume(returning: .failure(.fileSizeUnavailable))
            }
        }
    }
}

