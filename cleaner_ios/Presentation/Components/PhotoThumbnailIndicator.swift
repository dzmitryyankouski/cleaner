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
                        PhotoView(photo: photo, quality: .low, contentMode: .fill)
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

private struct ThumbnailView: View {
    let photo: PhotoModel
    @State private var image: UIImage?
    @State private var isLoading = false
    
    private let manager = PHCachingImageManager()
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.gray.opacity(0.3)
                    .overlay(
                        Group {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.6)
                            } else {
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                        }
                    )
                    .onAppear {
                        loadThumbnail()
                    }
            }
        }
    }
    
    private func loadThumbnail() {
        guard !isLoading && image == nil else { return }
        isLoading = true
        
        Task {
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [photo.id], options: nil)
            guard let asset = assets.firstObject else {
                await MainActor.run {
                    isLoading = false
                }
                return
            }
            
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.isNetworkAccessAllowed = false
            options.resizeMode = .fast
            options.deliveryMode = .opportunistic
            
            let targetSize = CGSize(width: 150, height: 200)
            
            manager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                DispatchQueue.main.async {
                    self.image = image
                    self.isLoading = false
                }
            }
        }
    }
}

