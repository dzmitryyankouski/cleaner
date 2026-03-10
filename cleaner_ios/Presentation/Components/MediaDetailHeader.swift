import SwiftUI

struct MediaDetailHeader: View {
    @Binding var items: [MediaItem]
    @Binding var selectedItem: MediaItem?
    let fallbackItem: MediaItem

    private var currentItem: MediaItem {
        selectedItem ?? fallbackItem
    }

    var body: some View {
        switch currentItem {
        case .photo:
            PhotoDetailHeader(items: $items, selectedItem: $selectedItem)
        case .video:
            VideoDetailHeader(items: $items, selectedItem: $selectedItem)
        }
    }
}
