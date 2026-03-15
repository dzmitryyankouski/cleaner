import SwiftUI

private struct BestOneBadge: View {
    var body: some View {
        Group {
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

struct PhotoGridPreview: View {
    var namespace: Namespace.ID

    private let allPhotos: [PhotoModel]
    private var leftPhotos: [PhotoModel]
    private var rightPhotos: [PhotoModel]
    private var bottomPhotos: [PhotoModel]

    @State private var selectedItem: MediaItem?

    init(photos: [PhotoModel], namespace: Namespace.ID) {
        self.allPhotos = photos
        self.leftPhotos = Array(photos.prefix(1))
        self.rightPhotos = Array(photos.dropFirst(1).prefix(4))
        self.bottomPhotos = Array(photos.dropFirst(5))
        self.namespace = namespace
    }

    var body: some View {
        LazyVStack(spacing: 6) {
            HStack(alignment: .top, spacing: 6) {
                MediaGrid(
                    items: leftPhotos.map { .photo($0) },
                    selectedItem: $selectedItem,
                    columns: 1,
                    namespace: namespace,
                    bestPhotoId: allPhotos.first?.id
                )
                .overlay(alignment: .topLeading) {
                    BestOneBadge()
                }

                MediaGrid(
                    items: rightPhotos.map { .photo($0) },
                    selectedItem: $selectedItem,
                    columns: 2,
                    namespace: namespace
                )
            }
            MediaGrid(
                items: bottomPhotos.map { .photo($0) },
                selectedItem: $selectedItem,
                columns: 4,
                namespace: namespace
            )
        }
        .fullScreenCover(item: $selectedItem) { item in
            MediaDetailView(
                items: allPhotos.map { .photo($0) }, currentItem: item, namespace: namespace)
        }
    }
}
