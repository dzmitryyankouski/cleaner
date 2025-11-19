import UIKit
import Photos

enum PhotoQuality {
    case low
    case medium
    case high
}

final class ImageCache {
    static let shared = ImageCache()
    
    private let cache = NSCache<NSString, UIImage>()
    private let cacheQueue = DispatchQueue(label: "com.cleaner.imageCache", attributes: .concurrent)
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 200 * 1024 * 1024 // 200 MB
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func cacheKey(for photoId: String, quality: PhotoQuality) -> String {
        return "\(photoId)_\(quality)"
    }
    
    func getImage(for photoId: String, quality: PhotoQuality) -> UIImage? {
        let key = cacheKey(for: photoId, quality: quality)
        return cacheQueue.sync {
            return cache.object(forKey: NSString(string: key))
        }
    }
    
    func getBestAvailableImage(for photoId: String, startingFrom quality: PhotoQuality) -> (image: UIImage, quality: PhotoQuality)? {
        let qualitiesToCheck = getQualitiesToCheck(startingFrom: quality)
        
        return cacheQueue.sync {
            for qualityToCheck in qualitiesToCheck {
                let key = cacheKey(for: photoId, quality: qualityToCheck)
                if let image = cache.object(forKey: NSString(string: key)) {
                    return (image, qualityToCheck)
                }
            }
            return nil
        }
    }
    
    private func getQualitiesToCheck(startingFrom quality: PhotoQuality) -> [PhotoQuality] {
        switch quality {
        case .high:
            return [.high, .medium, .low]
        case .medium:
            return [.medium, .low]
        case .low:
            return [.low]
        }
    }
    
    func setImage(_ image: UIImage, for photoId: String, quality: PhotoQuality) {
        let key = cacheKey(for: photoId, quality: quality)
        let cost = calculateImageCost(image)
        
        cacheQueue.async(flags: .barrier) {
            self.cache.setObject(image, forKey: NSString(string: key), cost: cost)
        }
    }
    
    private func calculateImageCost(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        let bytesPerPixel = 4 // RGBA
        let width = cgImage.width
        let height = cgImage.height
        return width * height * bytesPerPixel
    }
    
    @objc private func clearCache() {
        cacheQueue.async(flags: .barrier) {
            self.cache.removeAllObjects()
            print("🗑️ Image cache cleared due to memory warning")
        }
    }
    
    func removeImage(for photoId: String, quality: PhotoQuality) {
        let key = cacheKey(for: photoId, quality: quality)
        cacheQueue.async(flags: .barrier) {
            self.cache.removeObject(forKey: NSString(string: key))
        }
    }
    
    func removeAllImages(for photoId: String) {
        cacheQueue.async(flags: .barrier) {
            let qualities: [PhotoQuality] = [.low, .medium, .high]
            for quality in qualities {
                let key = self.cacheKey(for: photoId, quality: quality)
                self.cache.removeObject(forKey: NSString(string: key))
            }
        }
    }
}

