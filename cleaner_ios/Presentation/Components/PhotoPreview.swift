import Photos
import SwiftUI

struct PhotoPreview: View {
    @Environment(\.photoPreviewNamespace) var photoPreviewNamespace
    @ObservedObject var viewModel: PhotoViewModel
    @State private var image: UIImage?
    @State private var isLoading = false

    var body: some View {
        Group {
            if viewModel.showPreviewModel,
               let previewPhoto = viewModel.previewPhoto,
               let namespace = photoPreviewNamespace {
                ZStack {
                    Color.black.opacity(0.8)
                        .ignoresSafeArea()
                        .onTapGesture {
                            closePreview()
                        }

                    if let image = image {

                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .matchedGeometryEffect(id: previewPhoto.id, in: namespace)
                            .onTapGesture {
                                closePreview()
                            }
                    }
                }
                .onAppear {
                    loadImage()
                }
                .onChange(of: viewModel.previewPhoto?.id) { _ in
                    print("🔄 previewPhoto changed to: \(viewModel.previewPhoto?.id)")
                    loadImage()
                }
                .ignoresSafeArea()
                .zIndex(1000)
            }
        }
    }
    
    private func closePreview() {
        withAnimation(.spring(response: 0.3, dampingFraction: 1)) {
            viewModel.showPreviewModel = false
            viewModel.previewPhoto = nil
        }
    }

    private func loadImage() {
        print("🔄 loadImage")
        guard let asset = viewModel.previewPhoto?.asset else {
            return
        }
        print("🔄 asset: \(asset)")
        isLoading = true
        
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .none
        options.isNetworkAccessAllowed = false

        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { result, _ in
            DispatchQueue.main.async {
                print("🔄 result: \(result)")
                self.image = result
                self.isLoading = false
            }
        }
    }
}
