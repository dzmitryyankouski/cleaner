import Foundation
import Photos
import AVFoundation

// MARK: - Video Asset Repository

/// Репозиторий для работы с видео ассетами из библиотеки
final class VideoAssetRepository: AssetRepositoryProtocol {
    
    // MARK: - Public Methods
    
    /// Загружает все видео из библиотеки
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
        
        // Загружаем видео
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let videos = PHAsset.fetchAssets(with: .video, options: fetchOptions)
        
        var assets: [PHAsset] = []
        videos.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
        return .success(assets)
    }
    
    /// Получает размер файла для видео
    func getFileSize(for asset: PHAsset) async -> Result<Int64, AssetError> {
        return await withCheckedContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = false
            
            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                if let urlAsset = avAsset as? AVURLAsset {
                    do {
                        let resourceValues = try urlAsset.url.resourceValues(forKeys: [.fileSizeKey])
                        let fileSize = Int64(resourceValues.fileSize ?? 0)
                        continuation.resume(returning: .success(fileSize))
                    } catch {
                        continuation.resume(returning: .failure(.fileSizeUnavailable))
                    }
                } else {
                    continuation.resume(returning: .failure(.fileSizeUnavailable))
                }
            }
        }
    }
    
    /// Получает AVAsset из PHAsset
    func getAVAsset(for asset: PHAsset) async -> AVAsset? {
        return await withCheckedContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = false
            
            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                continuation.resume(returning: avAsset)
            }
        }
    }
}

