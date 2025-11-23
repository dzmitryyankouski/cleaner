import Photos
import SwiftUI

struct PhotoView: View {
    let photo: PhotoModel
    let quality: PhotoQuality
    let contentMode: ContentMode

    @State private var image: UIImage?
    @State private var isLoading = false
    
    private let manager = PHCachingImageManager()
    
    init(photo: PhotoModel, quality: PhotoQuality, contentMode: ContentMode) {
        self.photo = photo
        self.quality = quality
        self.contentMode = contentMode
    }

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                Color.gray.opacity(contentMode == .fill ? 0.3 : 0)
                    .onAppear {
                        loadImageIfNeeded()
                    }
            }
        }
    }
    
    private func loadImageIfNeeded() {
        guard !isLoading else { return }

        if let cachedImage = ImageCache.shared.getImage(for: photo.id, quality: quality) {
            print("📦 Изображение нужного качества (\(quality)) загружено из кэша \(photo.id)")
            image = cachedImage
            return
        }

         if let bestAvailableImage = ImageCache.shared.getBestAvailableImage(for: photo.id, startingFrom: quality) {
            print("💾 Найдено изображение качества \(bestAvailableImage.quality) в кэше \(photo.id)")
            image = bestAvailableImage.image
        }

        print("🔍 Загрузка изображения качества \(quality) \(photo.id)")
        isLoading = true

        Task {
            guard let asset = await loadAsset() else {
                await MainActor.run {
                    isLoading = false
                }
                return
            }

            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.isNetworkAccessAllowed = false
            
            switch quality {
            case .low:
                options.resizeMode = .fast
                options.deliveryMode = .fastFormat
            case .medium:
                options.resizeMode = .exact
                options.deliveryMode = .opportunistic
            case .high:
                options.resizeMode = .none
                options.deliveryMode = .highQualityFormat
            }

            let targetSize = self.getTargetSize(for: quality)

            manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, info in
                guard let image = image else {
                    print("❌ Не удалось получить изображение")
                    return
                }

                if (self.image == nil) {
                    print("with animation")
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.image = image
                    }
                } else {
                    print("without animation")
                    self.image = image
                }
                
                ImageCache.shared.setImage(image, for: self.photo.id, quality: quality)
                print("💾 Изображение качества \(quality) закэшировано \(photo.id)")
            }
        }
    }

    private func loadAsset() async -> PHAsset? {
        let photoId = photo.id
        return await Task.detached(priority: .userInitiated) {
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [photoId], options: nil)
            guard let asset = assets.firstObject else { return nil }
            
            return asset
        }.value
    }

    private func getTargetSize(for quality: PhotoQuality) -> CGSize {
        switch quality {
        case .low:
            return CGSize(width: 150, height: 200)
        case .medium:
            return CGSize(width: 300, height: 400)
        case .high:
            return PHImageManagerMaximumSize
        }
    }
}