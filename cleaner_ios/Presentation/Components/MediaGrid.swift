import SwiftUI

struct MediaGrid: View {
    let items: [MediaItem]
    @Binding var selectedItem: MediaItem?
    var columns: Int = 4
    var namespace: Namespace.ID
    var bestPhotoId: String? = nil

    @Environment(\.mediaLibrary) var mediaLibrary

    private var rows: Int {
        (items.count + columns - 1) / columns
    }

    private var aspectRatio: CGFloat {
        let ratio = CGFloat(columns) / CGFloat(max(rows, 1))
        return (ratio * 100_000_000).rounded() / 100_000_000
    }

    var body: some View {
        Grid(
            items: items,
            columns: columns,
            namespace: namespace,
            selectedItem: $selectedItem,
            onTap: { item in
                if mediaLibrary?.hasSelection ?? false {
                    withAnimation {
                        mediaLibrary?.select(item)
                    }
                } else {
                    selectedItem = item
                }
            },
            onLongPress: { item in
                withAnimation {
                    mediaLibrary?.select(item)
                }
            }
        ) { item in
            switch item {
            case .photo(let photo):
                Photo(photo: photo, quality: .medium, contentMode: .fill)
            case .video(let video):
                VideoThumbnail(video: video)
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
    }
}
