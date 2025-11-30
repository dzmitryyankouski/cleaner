import Foundation
import Photos

final class PhotoAssetRepository: AssetRepositoryProtocol {
    
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
            var totalSize: Int64 = 0
            var hasError = false

            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true

            let dispatch = DispatchGroup()

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
                    continuation.resume(returning: .success(totalSize))
                }
            }
        }
    }

    func isModified(for asset: PHAsset) -> Bool {
        let resources = PHAssetResource.assetResources(for: asset)
        return resources.contains(where: { resource in
            resource.type == .adjustmentData ||
            resource.type == .adjustmentBasePhoto
        })
    }
}
