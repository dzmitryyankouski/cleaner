import Photos
import SwiftUI

enum PhotoQuality {
    case low
    case medium
    case high
}

struct PhotoView: View {
    @Environment(\.photoPreviewNamespace) var photoPreviewNamespace

    let photo: PhotoModel
    let quality: PhotoQuality
    let contentMode: ContentMode
    let onLoad: ((UIImage) -> Void)?
    let matchedGeometry: Bool

    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var requestID: PHImageRequestID = PHInvalidImageRequestID
    @State private var screenBounds: CGRect = UIScreen.main.bounds
    @State private var frameSize: CGSize = CGSize(width: 300, height: 300)
    
    init(photo: PhotoModel, quality: PhotoQuality, contentMode: ContentMode, onLoad: ((UIImage) -> Void)? = nil, matchedGeometry: Bool = true) {
        self.photo = photo
        self.quality = quality
        self.contentMode = contentMode
        self.onLoad = onLoad
        self.matchedGeometry = matchedGeometry
    }

    var body: some View {
        if let namespace = photoPreviewNamespace {
            let baseView = Color.clear
                .overlay {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            
            Group {
                if matchedGeometry {
                    baseView.matchedGeometryEffect(id: photo.id, in: namespace)
                } else {
                    baseView
                }
            }
            .onAppear {
                loadImage()
            }
            .onDisappear {
                cancelLoad()
            }
        }
    }
    
    private func cancelLoad() {
        if requestID != PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(requestID)
            requestID = PHInvalidImageRequestID
        }
        isLoading = false
    }

     private func loadImage() {
        guard !isLoading && image == nil else { return }

        isLoading = true

        // Загружаем asset асинхронно в фоновом потоке
        Task {
            guard let asset = await photo.loadAsset() else {
                await MainActor.run {
                    isLoading = false
                }
                return
            }
            
            // После получения asset, загружаем изображение
            await loadImageFromAsset(asset)
        }
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
        
        await withCheckedContinuation { continuation in
            let continuationWrapper = ContinuationWrapper(continuation: continuation)
            
            self.requestID = PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { result, info in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                
                Task { @MainActor in
                    if self.requestID != PHInvalidImageRequestID {
                        self.image = result
                        
                        // Для low quality или не degraded изображений завершаем загрузку
                        if !isDegraded || self.quality == .low {
                            self.isLoading = false

                            if let onLoad = self.onLoad, let result = result {
                                onLoad(result)
                            }
                        }
                    }
                    
                    // Вызываем continuation только один раз
                    continuationWrapper.resumeOnce()
                }
            }
        }
    }
    
    // Вспомогательный класс для безопасного вызова continuation только один раз
    private class ContinuationWrapper {
        private let continuation: CheckedContinuation<Void, Never>
        private var hasResumed = false
        private let queue = DispatchQueue(label: "com.cleaner.continuation")
        
        init(continuation: CheckedContinuation<Void, Never>) {
            self.continuation = continuation
        }
        
        func resumeOnce() {
            queue.sync {
                if !hasResumed {
                    hasResumed = true
                    continuation.resume()
                }
            }
        }
    }

    private func getTargetSize() -> CGSize {
        switch quality {
        case .low:
            return CGSize(width: 150, height: 150)
        case .medium:
            return CGSize(width: 300, height: 300)
        case .high:
            return PHImageManagerMaximumSize
        }
    }
}