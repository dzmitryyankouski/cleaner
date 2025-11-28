import Foundation
import CoreGraphics
import CoreVideo
import Photos

protocol ImageProcessingProtocol {
    func convertAssetToPixelBuffer(_ asset: PHAsset, targetSize: CGSize) async -> Result<CVPixelBuffer, ImageProcessingError>
    func convertCGImageToPixelBuffer(_ cgImage: CGImage, targetSize: CGSize) -> Result<CVPixelBuffer, ImageProcessingError>
}

enum ImageProcessingError: LocalizedError {
    case conversionFailed
    case invalidImage
    case invalidSize
    case pixelBufferCreationFailed
    case contextCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .conversionFailed:
            return "Не удалось конвертировать изображение"
        case .invalidImage:
            return "Некорректное изображение"
        case .invalidSize:
            return "Некорректный размер изображения"
        case .pixelBufferCreationFailed:
            return "Не удалось создать pixel buffer"
        case .contextCreationFailed:
            return "Не удалось создать графический контекст"
        }
    }
}
