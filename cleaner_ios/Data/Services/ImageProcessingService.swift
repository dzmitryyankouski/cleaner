import Foundation
import CoreGraphics
import CoreVideo
import Photos
import UIKit

// MARK: - Image Processing Service

/// Сервис для обработки изображений
final class ImageProcessingService: ImageProcessingProtocol {
    
    // MARK: - Constants
    
    private enum Constants {
        static let defaultTargetSize = CGSize(width: 256, height: 256)
        static let pixelFormatType = kCVPixelFormatType_32ARGB
        static let bitsPerComponent = 8
    }
    
    // MARK: - Public Methods
    
    func convertAssetToPixelBuffer(_ asset: PHAsset, targetSize: CGSize) async -> Result<CVPixelBuffer, ImageProcessingError> {
        return await withCheckedContinuation { continuation in
            let imageManager = PHImageManager.default()
            let requestOptions = PHImageRequestOptions()
            
            requestOptions.isSynchronous = false
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.resizeMode = .exact
            requestOptions.isNetworkAccessAllowed = false
            
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: requestOptions
            ) { [weak self] image, info in
                guard let self = self else {
                    continuation.resume(returning: .failure(.conversionFailed))
                    return
                }
                
                guard let image = image, let cgImage = image.cgImage else {
                    continuation.resume(returning: .failure(.invalidImage))
                    return
                }
                
                let result = self.convertCGImageToPixelBuffer(cgImage, targetSize: targetSize)
                continuation.resume(returning: result)
            }
        }
    }
    
    func convertCGImageToPixelBuffer(_ cgImage: CGImage, targetSize: CGSize) -> Result<CVPixelBuffer, ImageProcessingError> {
        guard targetSize.width > 0 && targetSize.height > 0 else {
            return .failure(.invalidSize)
        }
        
        let width = Int(targetSize.width)
        let height = Int(targetSize.height)
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            Constants.pixelFormatType,
            nil,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return .failure(.pixelBufferCreationFailed)
        }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        defer { CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0)) }
        
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: pixelData,
            width: width,
            height: height,
            bitsPerComponent: Constants.bitsPerComponent,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            return .failure(.contextCreationFailed)
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return .success(buffer)
    }
}

