import SwiftUI

struct PhotoDetailView: View {
    let photos: [PhotoModel]
    let currentPhotoId: String
    var namespace: Namespace.ID
    @State private var selectedPhotoId: String? = nil

    var body: some View {
        TabView(selection: $selectedPhotoId) {
            ForEach(photos, id: \.id) { photo in
                PhotoView(
                    photo: photo, quality: .high, contentMode: .fit
                )
                .id(photo.id)
                .tag(photo.id)
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .navigationTitle("Группа (\(photos.count))")
        .navigationBarTitleDisplayMode(.inline)
        .navigationTransition(.zoom(sourceID: currentPhotoId, in: namespace))
        .onAppear {
            selectedPhotoId = currentPhotoId
        }
    }
}

