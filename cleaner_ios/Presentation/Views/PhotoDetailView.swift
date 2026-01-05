import Photos
import SwiftUI

struct PhotoDetailView: View {
    // MARK: - Environment
    @Environment(\.photoLibrary) var photoLibrary
    
    // MARK: - Parameters
    @State var photos: [PhotoModel]
    let currentItem: PhotoModel
    let namespace: Namespace.ID
    
    // MARK: - Private State
    @State private var assets: [String: PHAsset] = [:]
    @State private var selectedItem: PhotoModel? = nil

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedItem) {
                ForEach(photos, id: \.id) { photo in
                    GeometryReader { geometry in
                        Photo(photo: photo, quality: .high, contentMode: .fit)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    }
                    .id(photo.id)
                    .tag(photo)
                    .ignoresSafeArea()
                }
            }
            .onAppear {
                selectedItem = currentItem
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
        }
        .overlay(
            VStack {
                PhotoDetailHeader(photos: $photos, selectedItem: $selectedItem)
                Spacer()
                PhotoThumbnailIndicator(photos: photos, selectedItem: $selectedItem)
            }
        )
        .navigationTransition(.zoom(sourceID: selectedItem?.id ?? currentItem.id, in: namespace))
    }
}
