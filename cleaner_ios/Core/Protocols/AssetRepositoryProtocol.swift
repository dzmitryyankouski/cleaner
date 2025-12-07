import Foundation
import Photos

protocol AssetRepositoryProtocol {
    func fetchAssets() async -> Result<[PHAsset], AssetError>
    func getFileSize(for asset: PHAsset) async -> Result<Int64, AssetError>
    func isModified(for asset: PHAsset) -> Bool
    func isFavorite(for asset: PHAsset) -> Bool
    func delete(assets: [PHAsset]) async -> Result<Void, AssetError>
}

enum AssetError: LocalizedError {
    case permissionDenied
    case permissionRestricted
    case loadingFailed
    case fileSizeUnavailable
    case assetNotFound
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Доступ к фототеке запрещен"
        case .permissionRestricted:
            return "Доступ к фототеке ограничен"
        case .loadingFailed:
            return "Не удалось загрузить ассеты"
        case .fileSizeUnavailable:
            return "Размер файла недоступен"
        case .assetNotFound:
            return "Ассет не найден"
        }
    }
}
