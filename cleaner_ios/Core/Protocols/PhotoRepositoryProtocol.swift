import Foundation
import Photos
import UIKit

struct PhotoResourceSizes: Sendable {
    let total: Int64
    let liveVideo: Int64
}

protocol PhotoRepositoryProtocol {
    func getFileSize(for asset: PHAsset) async -> Result<Int64, AssetError>
    func getResourceSizes(for asset: PHAsset) async -> Result<PhotoResourceSizes, AssetError>
    func isModified(for asset: PHAsset) -> Bool
    func isFavorite(for asset: PHAsset) -> Bool

    func fetchAll(filter: Set<FilterPhoto>, sort: SortPhoto) async -> Result<[PhotoModel], AssetError>
    func delete(photos: [PhotoModel]) async -> Result<Void, AssetError>
    func removeLive(photo: PhotoModel) async -> Result<Void, AssetError>
    func compress(photo: PhotoModel, quality: CGFloat) async -> Result<PhotoModel, AssetError>
}
