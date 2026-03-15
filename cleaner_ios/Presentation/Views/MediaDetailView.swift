import SwiftUI

struct MediaDetailView: View {
    @State var items: [MediaItem]
    let currentItem: MediaItem
    let namespace: Namespace.ID

    @State private var selectedItem: MediaItem?

    var body: some View {
        MediaDetailPager(items: items, selectedItem: $selectedItem)
            .onAppear {
                selectedItem = currentItem
                preloadNeighbors(for: currentItem)
            }
            .onChange(of: selectedItem) { _, newValue in
                if let newValue {
                    preloadNeighbors(for: newValue)
                }
            }
        .overlay(alignment: .top) {
            MediaDetailHeader(items: $items, selectedItem: $selectedItem, fallbackItem: currentItem)
        }
        .overlay(alignment: .bottom) {
            MediaDetailThumbnails(items: items, selectedItem: $selectedItem)
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationTransition(.zoom(sourceID: selectedItem?.id ?? currentItem.id, in: namespace))
    }

    private func preloadNeighbors(for item: MediaItem) {
        guard case .photo(let photo) = item else { return }
        guard let currentIndex = items.firstIndex(where: { $0.id == photo.id }) else { return }

        for offset in [-2, -1, 1, 2] {
            let index = currentIndex + offset
            guard index >= 0 && index < items.count else { continue }
            guard case .photo(let neighbor) = items[index] else { continue }

            Task {
                _ = await neighbor.loadImage(quality: .high)
            }
        }
    }
}
