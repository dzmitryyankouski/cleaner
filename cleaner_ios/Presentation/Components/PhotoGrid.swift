import SwiftUI

struct PhotoGrid: View {
    let photos: [PhotoModel]
    var columns: Int = 3

    @Environment(\.photoLibrary) var photoLibrary

    @State private var selectedPhoto: PhotoModel? = nil

    var namespace: Namespace.ID

    private let spacing: CGFloat = 6

    private var rows: Int {
        (photos.count + columns - 1) / columns
    }

    private var aspectRatio: CGFloat {
        let ratio = CGFloat(columns) / CGFloat(max(rows, 1))
        return (ratio * 100_000_000).rounded() / 100_000_000
    }

    var body: some View {
        Group {
            if photos.isEmpty {
                EmptyView()
            } else {
                GeometryReader { geometry in
                    let availableWidth = geometry.size.width
                    let cellSize = (availableWidth - spacing * CGFloat(columns - 1)) / CGFloat(columns)
                    let gridColumns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)

                    LazyVGrid(columns: gridColumns, spacing: spacing) {
                        ForEach(photos, id: \.id) { photo in
                            Photo(photo: photo, quality: .medium, contentMode: .fill)
                                .frame(width: cellSize, height: cellSize)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    Group {
                                        if photoLibrary?.selectedPhotos.contains(photo) ?? false {
                                            Color.white.opacity(0.5)
                                        }
                                    }
                                    .transaction { $0.animation = nil }
                                )
                                .onTapGesture {
                                    if photoLibrary?.selectedPhotos.isEmpty ?? true {
                                        selectedPhoto = photo
                                    } else {
                                        withAnimation {
                                            photoLibrary?.select(photo: photo)
                                        }
                                        print(
                                            "selected photos: \(photoLibrary?.selectedPhotos.count ?? 0)"
                                        )
                                    }
                                }
                                .highPriorityGesture(
                                    LongPressGesture(minimumDuration: 0.3)
                                        .onEnded { _ in
                                            withAnimation {
                                                photoLibrary?.select(photo: photo)
                                            }
                                        }
                                )
                                .id(photo.id)
                                .matchedTransitionSource(id: photo.id, in: namespace)
                        }
                    }
                }
                .aspectRatio(aspectRatio, contentMode: .fit)
                .fullScreenCover(item: $selectedPhoto) { photo in
                    PhotoDetailView(photos: photos, currentItem: photo, namespace: namespace)
                }
            }
        }
    }
}

struct PhotoGridPreview: View {
    var namespace: Namespace.ID

    private var leftPhotos: [PhotoModel]
    private var rightPhotos: [PhotoModel]
    private var bottomPhotos: [PhotoModel]

    init(photos: [PhotoModel], namespace: Namespace.ID) {
        self.leftPhotos = Array(photos.prefix(1))
        self.rightPhotos = Array(photos.dropFirst(1).prefix(4))
        self.bottomPhotos = Array(photos.dropFirst(5))
        self.namespace = namespace
    }

    var body: some View {
        LazyVStack(spacing: 6) {
            HStack(alignment: .top, spacing: 6) {
                PhotoGrid(photos: leftPhotos, columns: 1, namespace: namespace)
                PhotoGrid(photos: rightPhotos, columns: 2, namespace: namespace)
            }
            PhotoGrid(photos: bottomPhotos, columns: 4, namespace: namespace)
        }
    }
}
