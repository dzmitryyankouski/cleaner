import Foundation
import Photos
import SwiftData
import UIKit
import ImageIO
import UniformTypeIdentifiers

final class PhotoAssetRepository: PhotoRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context   
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

    func delete(photos: [PhotoModel]) async -> Result<Void, AssetError> {
        let assetsResult = await fetchAssetsForPhotos(photos: photos)
        guard case .success(let assets) = assetsResult else {
            return .failure(.loadingFailed)
        }

        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(assets as NSArray)
            }, completionHandler: { success, error in
                if success {
                    for photo in photos {
                        self.context.delete(photo)
                    }

                    do {
                        try self.context.save()
                    } catch {
                        continuation.resume(returning: .failure(.loadingFailed))
                        return
                    }

                    continuation.resume(returning: .success(()))
                } else {
                    continuation.resume(returning: .failure(.loadingFailed))
                }
            })
        }
    }

    func removeLive(photo: PhotoModel) async -> Result<Void, AssetError> {
        let assetsResult = await fetchAssetsForPhotos(photos: [photo])
        guard case .success(let assets) = assetsResult, let asset = assets.first else {
            return .failure(.loadingFailed)
        }

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
                        Task {
                            photo.isLivePhoto = false
                            let fileSizeResult = await self.getFileSize(for: asset)
                            if case .success(let fileSize) = fileSizeResult {
                                photo.fileSize = fileSize
                            }

                            do {
                                try self.context.save()
                                continuation.resume(returning: .success(()))
                            } catch {
                                continuation.resume(returning: .failure(.loadingFailed))
                            }
                        }
                    } else {
                        continuation.resume(returning: .failure(.loadingFailed))
                    }
                }
            }
        }
    }

    func fetchAll(filter: Set<FilterPhoto>, sort: SortPhoto) async -> Result<[PhotoModel], AssetError> {
        let assets = await fetchAssets()
        guard case .success(let assets) = assets else {
            return .failure(.loadingFailed)
        }

        for asset in assets {
            let assetId = asset.localIdentifier
            if let _ = try? context.fetch(FetchDescriptor<PhotoModel>(predicate: #Predicate<PhotoModel> { $0.id == assetId })).first {
                continue
            }

            context.insert(PhotoModel(asset: asset))
        }

        do {
            try context.save()
        } catch {
            return .failure(.loadingFailed)
        }

        let photos = try? context.fetch(PhotoModel.apply(filter: filter, sort: sort))

        guard let photos = photos else {
            return .failure(.loadingFailed)
        }

        return .success(photos)
    }

    func compress(photo: PhotoModel, quality: CGFloat) async -> Result<PhotoModel, AssetError> {
        let assetsResult = await fetchAssetsForPhotos(photos: [photo])
        guard case .success(let assets) = assetsResult, let asset = assets.first else {
            return .failure(.loadingFailed)
        }

        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.version = .current
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false

            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, dataUTI, orientation, _ in
                guard let data else {
                    continuation.resume(returning: .failure(.loadingFailed))
                    return
                }

                guard let image = UIImage(data: data) else {
                    continuation.resume(returning: .failure(.loadingFailed))
                    return
                }
                
                let originalFormat = dataUTI ?? ""
                let isHEIC = originalFormat.contains("heic") || originalFormat.contains("heif")
                
                let originalFileSize = photo.fileSize ?? Int64(data.count)
                
                let compressedData = isHEIC ? self.compressHEIC(image: image, quality: quality, orientation: orientation) : image.jpegData(compressionQuality: quality) 
                
                guard let compressedData = compressedData else {
                    continuation.resume(returning: .failure(.loadingFailed))
                    return
                }

                var placeholderAssetIdentifier: String?
                
                PHPhotoLibrary.shared().performChanges({
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .photo, data: compressedData, options: nil)
                    placeholderAssetIdentifier = request.placeholderForCreatedAsset?.localIdentifier
                }, completionHandler: { success, error in
                    guard success, let identifier = placeholderAssetIdentifier else {
                        continuation.resume(returning: .failure(.loadingFailed))
                        return
                    }
                    
                    let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
                    guard let newAsset = fetchResult.firstObject else {
                        continuation.resume(returning: .failure(.loadingFailed))
                        return
                    }
                    
                    let newPhotoModel = PhotoModel(asset: newAsset)
                    newPhotoModel.fileSize = Int64(compressedData.count)
                    newPhotoModel.isCompressed = true
                    newPhotoModel.embedding = photo.embedding
                    newPhotoModel.creationDate = photo.creationDate
                    newPhotoModel.groups = photo.groups
                    newPhotoModel.isLivePhoto = false
                    newPhotoModel.isScreenshot = photo.isScreenshot
                    newPhotoModel.isModified = true
                    
                    self.context.insert(newPhotoModel)

                    do {
                        try self.context.save()
                        continuation.resume(returning: .success(newPhotoModel))
                    } catch {
                        continuation.resume(returning: .failure(.loadingFailed))
                    }
                })
            }
        }
    }

    private func fetchAssets() async -> Result<[PHAsset], AssetError> {
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

    private func fetchAssetsForPhotos(photos: [PhotoModel]) async -> Result<[PHAsset], AssetError> {
        return await withCheckedContinuation { continuation in
            let assetIds = photos.map { $0.id }
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: assetIds, options: nil)
            
            var assets: [PHAsset] = []
            fetchResult.enumerateObjects { asset, _, _ in
                assets.append(asset)
            }
            
            continuation.resume(returning: .success(assets))
        }
    }
    
    private func compressHEIC(image: UIImage, quality: CGFloat, orientation: CGImagePropertyOrientation) -> Data? {
        guard let cgImage = image.cgImage else { return nil }
        
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(mutableData, UTType.heic.identifier as CFString, 1, nil) else {
            return nil
        }
        
        var options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        
        options[kCGImagePropertyOrientation] = orientation.rawValue
        
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        
        return mutableData as Data
    }
}
