import SwiftUI
import Photos

struct PhotoDetailView: View {
    let photos: [PhotoModel]
    let currentPhotoId: String
    var namespace: Namespace.ID

    @State private var selectedPhotoId: String? = nil
    @State private var assets: [String: PHAsset] = [:]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedPhotoId) {
                ForEach(photos, id: \.id) { photo in
                    GeometryReader { geometry in
                        Photo(photo: photo, quality: .high, contentMode: .fit)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    }
                    .id(photo.id)
                    .tag(photo.id)
                    .ignoresSafeArea()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onAppear {
                selectedPhotoId = currentPhotoId
            }
            .ignoresSafeArea()
        }
        .overlay(
            VStack {
                Spacer()
                PhotoThumbnailIndicator(photos: photos, selectedPhotoId: $selectedPhotoId)
            }
        )
        .navigationTitle("Группа (\(photos.count))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .navigationTransition(.zoom(sourceID: selectedPhotoId ?? currentPhotoId, in: namespace))
    }
}
