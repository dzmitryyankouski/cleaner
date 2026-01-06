import SwiftUI

struct PhotoGrid: View {
    let photos: [PhotoModel]

    @Environment(\.photoLibrary) var photoLibrary

    @State private var selectedPhoto: PhotoModel? = nil

    var namespace: Namespace.ID

    let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 1) {
            ForEach(photos, id: \.id) { photo in
                Photo(photo: photo, quality: .medium, contentMode: .fill)
                    .frame(width: UIScreen.main.bounds.width / 3 - (2 / 3), height: UIScreen.main.bounds.width / 2)
                    .clipped()
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
                            print("selected photos: \(photoLibrary?.selectedPhotos.count ?? 0)")
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
        .fullScreenCover(item: $selectedPhoto) { photo in
            PhotoDetailView(photos: photos, currentItem: photo, namespace: namespace)
        }
    }
}
