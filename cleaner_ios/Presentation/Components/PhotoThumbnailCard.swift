import SwiftUI
import Photos

// MARK: - Photo Thumbnail Card

/// Карточка с миниатюрой фотографии
struct PhotoThumbnailCard: View {
    let photo: Photo
    var size: CGSize = CGSize(width: 165, height: 220)
    let isSelected: Bool
    let onToggle: () -> Void
    
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .cornerRadius(8)
                    .overlay(overlayView)
            } else {
                placeholderView
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    // MARK: - Overlay View
    
    private var overlayView: some View {
        VStack {
            HStack {
                Spacer()
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Color.blue.opacity(0.8))
                    .cornerRadius(4)
            }
            Spacer()
            HStack {
                Spacer()
                Button(action: onToggle) {
                    Image(systemName: isSelected ? "trash.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isSelected ? .red : .white)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
            }
        }
        .padding(8)
    }
    
    // MARK: - Placeholder View
    
    private var placeholderView: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: size.width, height: size.height)
            .cornerRadius(8)
            .overlay(
                Group {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                            .font(.title2)
                    }
                }
            )
    }
    
    // MARK: - Private Methods
    
    private func loadImage() {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .opportunistic
        options.resizeMode = .exact
        
        PHImageManager.default().requestImage(
            for: photo.asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
        ) { result, _ in
            DispatchQueue.main.async {
                self.image = result
                self.isLoading = false
            }
        }
    }
}

