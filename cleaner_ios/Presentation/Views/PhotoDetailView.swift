import SwiftUI

struct PhotoDetailView: View {
    // MARK: - Environment
    @Environment(\.photoLibrary) var photoLibrary
    
    // MARK: - Parameters
    @State var photos: [PhotoModel]
    let currentItem: PhotoModel
    let namespace: Namespace.ID
    
    // MARK: - Private State
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
                preloadNeighbors(for: currentItem)
            }
            .onChange(of: selectedItem) { _, newValue in
                if let newValue {
                    preloadNeighbors(for: newValue)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
        }
        .overlay(
            VStack {
                PhotoDetailHeader(photos: $photos, selectedItem: $selectedItem)

                Spacer()

                ThumbnailIndicator(items: photos, selectedItem: $selectedItem) { photo in
                    Photo(photo: photo, quality: .low, contentMode: .fill)
                }
            }
        )
        .navigationTransition(.zoom(sourceID: selectedItem?.id ?? currentItem.id, in: namespace))
    }
    
    // MARK: - Preloading
    
    private func preloadNeighbors(for photo: PhotoModel) {
        guard let currentIndex = photos.firstIndex(where: { $0.id == photo.id }) else { return }
        
        // Предзагружаем соседние фото
        for offset in [-2, -1, 1, 2] {
            let index = currentIndex + offset
            guard index >= 0 && index < photos.count else { continue }
            let neighborPhoto = photos[index]
            Task { _ = await neighborPhoto.loadImage(quality: .high) }
        }
    }
}
