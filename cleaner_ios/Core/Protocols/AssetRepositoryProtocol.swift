import Foundation
import Photos

// MARK: - Asset Repository Protocol

/// Протокол для работы с фото и видео ассетами
protocol AssetRepositoryProtocol {
    /// Загружает все ассеты из библиотеки
    func fetchAssets() async -> Result<[PHAsset], AssetError>
    
    /// Получает размер файла для ассета
    func getFileSize(for asset: PHAsset) async -> Result<Int64, AssetError>
}

// MARK: - Asset Error

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

