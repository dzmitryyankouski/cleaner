import SwiftUI

struct PhotoDetailView: View {
    let group: PhotoGroupModel
    let currentPhotoId: String
    var namespace: Namespace.ID
    @State private var selectedPhotoId: String? = nil

    var body: some View {
        TabView(selection: $selectedPhotoId) {
            ForEach(group.photos, id: \.id) { photo in
                PhotoView(
                    photo: photo, quality: .high, contentMode: .fit
                )
                .id(photo.id)
                .tag(photo.id)
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .navigationTitle("Группа (\(group.photos.count))")
        .navigationBarTitleDisplayMode(.inline)
        .navigationTransition(.zoom(sourceID: currentPhotoId, in: namespace))
        .onAppear {
            selectedPhotoId = currentPhotoId
        }
    }
}

