import Photos
import SwiftUI

struct PhotoThumbnailCard: View {
    @Environment(\.photoPreviewNamespace) var photoPreviewNamespace

    let photo: Photo
    let onPreviewPhoto: () -> Void

    var body: some View {
        if let namespace = photoPreviewNamespace {
        PhotoView(photo: photo, quality: .low, contentMode: .fill)
            .frame(width: 150, height: 150)
                .onTapGesture {
                    onPreviewPhoto()
                }
        }
    }
}
