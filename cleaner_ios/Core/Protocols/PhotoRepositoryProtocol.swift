import Foundation
import Photos

protocol PhotoRepositoryProtocol {
    func getFileSize(for asset: PHAsset) async -> Result<Int64, AssetError>
    func isModified(for asset: PHAsset) -> Bool
    func isFavorite(for asset: PHAsset) -> Bool
    func delete(assets: [PHAsset]) async -> Result<Void, AssetError>
    func removeLive(asset: PHAsset) async -> Result<Void, AssetError>

    func fetchAll(filter: Set<FilterPhoto>, sort: SortPhoto) async -> Result<[PhotoModel], AssetError>
}
