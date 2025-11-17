import Photos
import SwiftUI

enum PhotoQuality {
    case low
    case medium
    case high
}

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
                        loadImage()
                    }
            }
        }
    }
    
    private func loadImage() {
        print("🔍 Загрузка изображения")
        guard !isLoading && image == nil else { return }

        isLoading = true

        // Загружаем asset асинхронно в фоновом потоке
        Task {
            guard let asset = await loadAsset() else {
                await MainActor.run {
                    isLoading = false
                }
                return
            }
            
            // После получения asset, загружаем изображение
            await loadImageFromAsset(asset)
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
    
    private func loadImageFromAsset(_ asset: PHAsset) async {
        let options = PHImageRequestOptions()
        
        options.isSynchronous = false
        options.isNetworkAccessAllowed = false
        options.deliveryMode = .opportunistic
        
        switch quality {
        case .low:
            options.resizeMode = .fast
        case .medium:
            options.resizeMode = .exact
        case .high:
            options.resizeMode = .none
            options.deliveryMode = .highQualityFormat
        }

        let targetSize = self.getTargetSize()
        
        manager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            self.image = image
        }
    }

    private func getTargetSize() -> CGSize {
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