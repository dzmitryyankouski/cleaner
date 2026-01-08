import Photos
import SwiftUI

struct Photo: View {
    let photo: PhotoModel
    let quality: PhotoQuality
    let contentMode: ContentMode
    let useAnimation: Bool

    @State private var image: UIImage?
    @State private var isLoading = false
    
    private let manager = PHCachingImageManager()
    
    init(photo: PhotoModel, quality: PhotoQuality, contentMode: ContentMode, useAnimation: Bool = false) {
        self.photo = photo
        self.quality = quality
        self.contentMode = contentMode
        self.useAnimation = useAnimation
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
        guard !isLoading && image == nil else { return }

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
                    print("❌ Cannot load image")
                    return
                }

                if self.useAnimation {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        self.image = image
                    }
                } else {
                    self.image = image
                }
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