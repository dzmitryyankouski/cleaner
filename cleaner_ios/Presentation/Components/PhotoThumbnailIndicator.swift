import SwiftUI
import Photos

struct PhotoThumbnailIndicator: View {
    let photos: [PhotoModel]
    @Binding var selectedPhotoId: String?
    
    private let thumbnailSize: CGFloat = 60
    private let spacing: CGFloat = 8
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: spacing) {
                    ForEach(photos, id: \.id) { photo in
                        Photo(photo: photo, quality: .low, contentMode: .fill)
                            .frame(width: photo.id == selectedPhotoId ? 50 : 30, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .id(photo.id)
                            .onTapGesture {
                                selectedPhotoId = photo.id
                            }
                            .animation(.easeInOut(duration: 0.2), value: selectedPhotoId)
                    }
                }
                .padding(.horizontal, spacing)
            }
            .frame(height: 50)
            .onChange(of: selectedPhotoId) { newValue in
                if let newValue = newValue {
                    withAnimation {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
    }
}
