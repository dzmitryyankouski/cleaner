import Photos
import SwiftUI

enum PhotoQuality {
    case low
    case medium
    case high
}

struct PhotoView: View {
    @Environment(\.photoPreviewNamespace) var photoPreviewNamespace

    let photo: Photo
    let size: CGSize
    let quality: PhotoQuality
    let contentMode: ContentMode?

    @Binding var frameSize: CGSize

    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var requestID: PHImageRequestID = PHInvalidImageRequestID
    @State private var screenBounds: CGRect = UIScreen.main.bounds

    var body: some View {
        if let namespace = photoPreviewNamespace {
            Color.clear
                .overlay {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: contentMode ?? .fill)
                    }
                }

                .clipped()
                .matchedGeometryEffect(id: photo.id, in: namespace)
                .onAppear {
                    loadImage()
                }
        }
    }

     private func loadImage() {
        guard !isLoading && image == nil else { return }

        isLoading = true

        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.isNetworkAccessAllowed = false

        switch quality {
        case .low:
            options.deliveryMode = .opportunistic
            options.resizeMode = .fast
        case .medium:
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact
        case .high:
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .none
        }

        var capturedRequestID: PHImageRequestID = PHInvalidImageRequestID

        let currentRequestID = PHImageManager.default().requestImage(
            for: photo.asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
        ) { result, _ in
            DispatchQueue.main.async {
                if self.requestID == capturedRequestID {
                    self.image = result
                    self.isLoading = false
                }
            }

           // self.updateLayout()
        }

        capturedRequestID = currentRequestID
        self.requestID = currentRequestID
    }

    private func updateLayout() {
        print("🔄 updateLayout for photo: \(photo.id)")
        guard let image = image else { return }

        let imageSize = image.size
        let imageAspectRatio = imageSize.width / imageSize.height

        let containerWidth = screenBounds.width
        let containerHeight = screenBounds.height
        let containerAspectRatio = containerWidth / containerHeight

        let baseFrameWidth: CGFloat =
            imageAspectRatio > containerAspectRatio
            ? containerWidth
            : containerHeight * imageAspectRatio

        let baseFrameHeight: CGFloat =
            imageAspectRatio > containerAspectRatio
            ? containerWidth / imageAspectRatio
            : containerHeight

        frameSize = CGSize(width: baseFrameWidth, height: baseFrameHeight)
    }
}