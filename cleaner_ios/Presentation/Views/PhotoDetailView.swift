import SwiftUI
import Photos

struct PhotoDetailView: View {
    let photos: [PhotoModel]
    let currentPhotoId: String
    var namespace: Namespace.ID
    @State private var selectedPhotoId: String? = nil
    @State private var assets: [String: PHAsset] = [:]

    var body: some View {
        TabView(selection: $selectedPhotoId) {
            ForEach(photos, id: \.id) { photo in
                GeometryReader { geometry in
                    PhotoView(photo: photo, quality: .high, contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
                .id(photo.id)
                .tag(photo.id)
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .navigationTitle("Группа (\(photos.count))")
        .navigationBarTitleDisplayMode(.inline)
        .navigationTransition(.zoom(sourceID: selectedPhotoId ?? currentPhotoId, in: namespace))
        .onAppear {
            selectedPhotoId = currentPhotoId
        }
    }
}
