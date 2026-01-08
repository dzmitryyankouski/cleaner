import SwiftUI

struct VideoThumbnail: View {
    let video: VideoModel
    
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.gray.opacity(0.3)
                    .task {
                        guard let loaded = await video.loadPreview() else { return }
                        image = loaded
                    }
            }
        }
    }
}