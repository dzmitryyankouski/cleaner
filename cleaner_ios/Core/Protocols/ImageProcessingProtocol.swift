import Foundation
import CoreGraphics
import CoreVideo
import Photos

// MARK: - Image Processing Protocol

/// Протокол для обработки изображений
protocol ImageProcessingProtocol {
    /// Конвертирует PHAsset в CVPixelBuffer
    func convertAssetToPixelBuffer(_ asset: PHAsset, targetSize: CGSize) async -> Result<CVPixelBuffer, ImageProcessingError>
    
    /// Конвертирует CGImage в CVPixelBuffer
    func convertCGImageToPixelBuffer(_ cgImage: CGImage, targetSize: CGSize) -> Result<CVPixelBuffer, ImageProcessingError>
}

// MARK: - Image Processing Error

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

