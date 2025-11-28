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

    /// Получает размер файла для фото
    func getFileSize(for asset: PHAsset) async -> Result<Int64, AssetError> {
        return await withCheckedContinuation { continuation in
            let start = Date()

            let resources = PHAssetResource.assetResources(for: asset)
            var totalSize: Int64 = 0
            var hasError = false

            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true

            let dispatch = DispatchGroup()

            // Если нет ресурсов, возвращаем 0
            if resources.isEmpty {
                continuation.resume(returning: .success(0))
                return
            }

            for resource in resources {
                dispatch.enter()

                PHAssetResourceManager.default().requestData(for: resource, options: options) { data in
                    totalSize += Int64(data.count)
                } completionHandler: { error in
                    if error != nil {
                        hasError = true
                    }
                    dispatch.leave()
                }
            }

            dispatch.notify(queue: .main) {
                if hasError {
                    continuation.resume(returning: .failure(.fileSizeUnavailable))
                } else {
                    let end = Date()
                    let duration = end.timeIntervalSince(start)
                    print("getFileSize duration: \(duration) seconds")
                    continuation.resume(returning: .success(totalSize))
                }
            }
        }
    }
}

