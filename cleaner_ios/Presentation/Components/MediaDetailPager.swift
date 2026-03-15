import SwiftUI

struct MediaDetailPager: View {
    let items: [MediaItem]
    @Binding var selectedItem: MediaItem?

    var body: some View {
        TabView(selection: $selectedItem) {
            ForEach(items, id: \.id) { item in
                MediaPage(item: item, isSelected: selectedItem?.id == item.id)
                    .id(item.id)
                    .tag(item)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
    }
}

private struct MediaPage: View {
    let item: MediaItem
    let isSelected: Bool

    var body: some View {
        switch item {
        case .photo(let photo):
            GeometryReader { geometry in
                Photo(photo: photo, quality: .high, contentMode: .fit)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }
            .ignoresSafeArea()
        case .video(let video):
            VStack {
                VideoPlayerCard(video: video, isSelected: isSelected)
            }
            .ignoresSafeArea()
        }
    }
}
