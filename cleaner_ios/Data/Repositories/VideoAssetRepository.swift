import Foundation
import Photos
import AVFoundation

// MARK: - Video Asset Repository

/// Репозиторий для работы с видео ассетами из библиотеки
final class VideoAssetRepository {
    
    // MARK: - Public Methods
    
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

