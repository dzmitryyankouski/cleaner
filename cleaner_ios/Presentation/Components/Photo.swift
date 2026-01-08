import SwiftUI

struct Photo: View {
    let photo: PhotoModel
    let quality: PhotoQuality
    let contentMode: ContentMode

    @State private var image: UIImage?
    
    init(photo: PhotoModel, quality: PhotoQuality, contentMode: ContentMode) {
        self.photo = photo
        self.quality = quality
        self.contentMode = contentMode
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                Color.gray.opacity(contentMode == .fill ? 0.3 : 0)
                    .task {
                        guard let loadedImage = await photo.loadImage(quality: quality) else { return }
                        image = loadedImage
                    }
            }
        }
    }
}