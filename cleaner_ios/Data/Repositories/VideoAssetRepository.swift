import Foundation
import Photos
import AVFoundation

final class VideoAssetRepository: AssetRepositoryProtocol {
    
    func fetchAssets() async -> Result<[PHAsset], AssetError> {
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
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let videos = PHAsset.fetchAssets(with: .video, options: fetchOptions)
        
        var assets: [PHAsset] = []
        videos.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
        return .success(assets)
    }
    
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

    func isModified(for asset: PHAsset) -> Bool {
        let resources = PHAssetResource.assetResources(for: asset)
        return resources.contains(where: { resource in
            resource.type == .adjustmentData ||
            resource.type == .adjustmentBaseVideo
        })
    }

    func isFavorite(for asset: PHAsset) -> Bool {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "localIdentifier == %@", asset.localIdentifier)

        let favCollection = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .smartAlbumFavorites,
            options: nil
        ).firstObject

        guard let favCollection = favCollection else { return false }

        return PHAsset.fetchAssets(in: favCollection, options: options).count > 0
    }
    
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
