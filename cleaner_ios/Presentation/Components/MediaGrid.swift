import SwiftUI

private struct BestOneBadge: View {
    let show: Bool

    var body: some View {
        Group {
            if show {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                    Text("best one")
                        .font(.system(size: 12, weight: .semibold))
                }
                .frame(height: 22)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 21)
                        .fill(Color(red: 0.2, green: 0.8, blue: 0.4))
                )
                .padding(6)
            }
        }
    }
}

struct MediaGrid: View {
    let items: [MediaItem]
    var columns: Int = 4
    var namespace: Namespace.ID
    var bestPhotoId: String? = nil

    @Environment(\.mediaLibrary) var mediaLibrary

    @State private var selectedItem: MediaItem?

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
            },
            cellAspectRatio: { _ in 1 }
        ) { item in
            switch item {
            case .photo(let photo):
                Photo(photo: photo, quality: .medium, contentMode: .fill)
                    .overlay(alignment: .topLeading) {
                        BestOneBadge(show: bestPhotoId == photo.id)
                    }
            case .video(let video):
                VideoThumbnail(video: video)
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .fullScreenCover(item: $selectedItem) { item in
            MediaDetailView(items: items, currentItem: item, namespace: namespace)
        }
    }
}
