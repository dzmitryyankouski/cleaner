import Photos
import SwiftUI

struct PhotoPreview: View {
    @Environment(\.photoPreviewNamespace) var photoPreviewNamespace
    @ObservedObject var viewModel: PhotoViewModel
    
    private let targetSize = CGSize(width: 300, height: 400)

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

                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .cornerRadius(16)
                        .matchedGeometryEffect(id: previewPhoto.id, in: namespace)
                        .frame(width: targetSize.width, height: targetSize.height)
                        .onTapGesture {
                            closePreview()
                        }
                }
                .ignoresSafeArea()
                .zIndex(1000)
            }
        }
    }
    
    private func closePreview() {
        withAnimation(.spring(response: 3, dampingFraction: 1)) {
            viewModel.showPreviewModel = false
            viewModel.previewPhoto = nil
        }
    }
}
