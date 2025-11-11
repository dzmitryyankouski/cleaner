import Photos
import SwiftUI

struct PhotoPreview: View {
    @Environment(\.photoPreviewNamespace) var photoPreviewNamespace
    @EnvironmentObject var viewModel: PhotoViewModel

    @State private var offset: CGSize = .zero
    @State private var selected: String?
    @State private var showOverlay = false
    @State private var showTabView = false
    @State private var baseFrameSize: CGSize = CGSize(width: 500, height: 500)
    @State private var isDragging = false

    private let basicSize: CGSize = CGSize(width: 500, height: 500)

    var body: some View {
        Group {
            if let namespace = photoPreviewNamespace, let previewPhoto = viewModel.previewPhoto?.photo {
                ZStack {
                    Color.white
                        .ignoresSafeArea()
                        .opacity(max(0.6, (0.9 - abs(offset.height) / 1000.0)))

                    // if showTabView {
                    //     TabView(selection: $selected) {
                    //         ForEach(viewModel.previewPhoto?.items ?? [], id: \.self) { photo in
                    //             PhotoView(photo: photo, size: basicSize, quality: .high, contentMode: .fit, frameSize: $baseFrameSize)
                    //                 .frame(maxWidth: .infinity, maxHeight: .infinity)
                    //                 .offset(x: offset.width, y: offset.height)
                    //                 .scaleEffect(1 - (abs(offset.height) / 1000))
                    //                 .animation(.interactiveSpring(response: 0.1, dampingFraction: 0.95), value: offset)
                    //                 .tag(photo.id)
                    //         }
                    //     }
                    //     .tabViewStyle(.page(indexDisplayMode: .never))
                    // }

                    PhotoView(photo: previewPhoto, size: basicSize, quality: .high, contentMode: .fill, frameSize: $baseFrameSize)
                        .frame(width: 400, height: 400)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .offset(x: offset.width, y: offset.height)
                        .gesture(overlayDragGesture())
                       // .opacity(showOverlay ? 1 : 0)
                }
                .zIndex(2)
                .onAppear {
                    if selected == nil {
                        selected = viewModel.previewPhoto?.photo.id
                    }
                    
                    showOverlay = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        showOverlay = false
                        showTabView = true
                    }
                }
            }
        }
    }

     private func overlayDragGesture() -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                isDragging = isDragging || abs(value.translation.width) < abs(value.translation.height)

                if viewModel.previewPhoto != nil && isDragging {
                    showOverlay = true
                    offset = value.translation
                }
            }
            .onEnded { value in
                isDragging = false

                if viewModel.previewPhoto != nil && abs(value.translation.height) < 100 && abs(value.predictedEndTranslation.height) < 250 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.95)) {
                        offset = .zero
                    }
                    
                    withAnimation(.spring(response: 0.1, dampingFraction: 0.95)) {
                        showOverlay = false
                    }
                } else {
                    showTabView = false

                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        offset = .zero
                        viewModel.previewPhoto = nil
                    }
                }
            }
    }

    // private func loadImage(photo: Photo) {
    //     print("🔄 loadImage for preview")
    //     guard let asset = photo.asset else {
    //         return
    //     }

    //     print("🔄 asset: \(asset)")
        
    //     let options = PHImageRequestOptions()
    //     options.isSynchronous = false
    //     options.deliveryMode = .highQualityFormat
    //     options.resizeMode = .none
    //     options.isNetworkAccessAllowed = false

        
    //     PHImageManager.default().requestImage(
    //         for: asset,
    //         targetSize: PHImageManagerMaximumSize,
    //         contentMode: .aspectFit,
    //         options: options
    //     ) { result, _ in
    //         DispatchQueue.main.async {
    //             print("🔄 result: \(result)")
    //             photos.append(result)
    //         }
    //     }
    // }

    // private func updateLayout(for id: String?) {
    //     guard let photo = photos.first(where: { $0.id == index }) else {
    //         return
    //     }

    //     let imageSize = photo.size
    //     let imageAspectRatio = imageSize.width / imageSize.height

    //     let containerWidth = screenBounds.width
    //     let containerHeight = screenBounds.height
    //     let containerAspectRatio = containerWidth / containerHeight

    //     let baseFrameWidth: CGFloat =
    //         imageAspectRatio > containerAspectRatio
    //         ? containerWidth
    //         : containerHeight * imageAspectRatio

    //     let baseFrameHeight: CGFloat =
    //         imageAspectRatio > containerAspectRatio
    //         ? containerWidth / imageAspectRatio
    //         : containerHeight

    //     baseFrameSize = CGSize(width: baseFrameWidth, height: baseFrameHeight)
    // }
}
