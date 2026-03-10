import SwiftUI

struct PhotoGridPreview: View {
    var namespace: Namespace.ID

    private let allPhotos: [PhotoModel]
    private var leftPhotos: [PhotoModel]
    private var rightPhotos: [PhotoModel]
    private var bottomPhotos: [PhotoModel]

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
                    columns: 1,
                    namespace: namespace,
                    bestPhotoId: allPhotos.first?.id
                )
                MediaGrid(
                    items: rightPhotos.map { .photo($0) },
                    columns: 2,
                    namespace: namespace
                )
            }
            MediaGrid(
                items: bottomPhotos.map { .photo($0) },
                columns: 4,
                namespace: namespace
            )
        }
    }
}
