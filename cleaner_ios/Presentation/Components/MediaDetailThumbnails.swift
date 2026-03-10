import SwiftUI

struct MediaDetailThumbnails: View {
    let items: [MediaItem]
    @Binding var selectedItem: MediaItem?

    var body: some View {
        ThumbnailIndicator(items: items, selectedItem: $selectedItem) { item in
            switch item {
            case .photo(let photo):
                Photo(photo: photo, quality: .low, contentMode: .fill)
            case .video(let video):
                VideoThumbnail(video: video)
            }
        }
        .padding(.vertical, 20)
        .background(
            LinearGradient(
                colors: [.clear, .white],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
