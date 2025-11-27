import SwiftUI

struct PhotoGridView: View {
    let photos: [PhotoModel]

    @Environment(\.photoLibrary) var photoLibrary
    @Binding var navigationPath: NavigationPath

    var namespace: Namespace.ID

    let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 1) {
            ForEach(photos, id: \.id) { photo in
                PhotoView(photo: photo, quality: .medium, contentMode: .fill)
                    .frame(width: UIScreen.main.bounds.width / 3 - (2 / 3), height: UIScreen.main.bounds.width / 2)
                    .clipped()
                    .onTapGesture {
                        navigationPath.append(PhotoGroupNavigationItem(photos: photos, currentPhotoId: photo.id))
                    }
                    .id(photo.id)
                    .matchedTransitionSource(id: photo.id, in: namespace)
            }
        }
    }
}
