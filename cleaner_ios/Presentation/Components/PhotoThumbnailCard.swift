import Photos
import SwiftUI

struct PhotoThumbnailCard: View {
    let photo: PhotoModel

    var body: some View {
        PhotoView(photo: photo, quality: .medium, contentMode: .fill)
            .frame(width: 150, height: 200)
    }
}
