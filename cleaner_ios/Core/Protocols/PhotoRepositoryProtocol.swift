import Foundation
import Photos

protocol PhotoRepositoryProtocol {
    func getFileSize(for asset: PHAsset) async -> Result<Int64, AssetError>
    func isModified(for asset: PHAsset) -> Bool
    func isFavorite(for asset: PHAsset) -> Bool

    func fetchAll(filter: Set<FilterPhoto>, sort: SortPhoto) async -> Result<[PhotoModel], AssetError>
    func delete(photos: [PhotoModel]) async -> Result<Void, AssetError>
    func removeLive(photo: PhotoModel) async -> Result<Void, AssetError>
}
