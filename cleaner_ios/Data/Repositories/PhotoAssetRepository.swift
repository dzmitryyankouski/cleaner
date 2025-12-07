import Foundation
import Photos
import SwiftData

final class PhotoAssetRepository: PhotoRepositoryProtocol {

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

                PHAssetResourceManager.default().requestData(for: resource, options: options) {
                    data in
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
            resource.type == .adjustmentData || resource.type == .adjustmentBasePhoto
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

    func delete(assets: [PHAsset]) async -> Result<Void, AssetError> {
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges(
                {
                    PHAssetChangeRequest.deleteAssets(assets as NSArray)
                },
                completionHandler: { success, error in
                    if success {
                        continuation.resume(returning: .success(()))
                    } else {
                        continuation.resume(returning: .failure(.loadingFailed))
                    }
                })
        }
    }

    func removeLive(asset: PHAsset) async -> Result<Void, AssetError> {
        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.version = .current
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false

            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) {
                data, _, _, _ in
                guard let data else {
                    continuation.resume(returning: .failure(.loadingFailed))
                    return
                }

                PHPhotoLibrary.shared().performChanges {
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .photo, data: data, options: nil)
                } completionHandler: { success, error in
                    if success {
                        continuation.resume(returning: .success(()))
                    } else {
                        continuation.resume(returning: .failure(.loadingFailed))
                    }
                }
            }
        }
    }
}
