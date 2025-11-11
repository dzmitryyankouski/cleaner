import Photos
import SwiftUI

struct PhotoThumbnailCard: View {
    @Environment(\.photoPreviewNamespace) var photoPreviewNamespace

    let photo: Photo
    let onPreviewPhoto: (CGSize) -> Void

    @State private var frameSize: CGSize = .zero

    var body: some View {
        if let namespace = photoPreviewNamespace {
        PhotoView(photo: photo, size: CGSize(width: 150, height: 150), quality: .low, contentMode: .fill, frameSize: $frameSize)
            .matchedGeometryEffect(id: photo.id, in: namespace)
            .frame(width: 150, height: 150)
                .onTapGesture {
                    onPreviewPhoto(frameSize)
                }
        }
    }
}
