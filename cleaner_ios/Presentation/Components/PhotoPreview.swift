import Photos
import SwiftUI

struct PhotoPreview: View {
    @Environment(\.photoPreviewNamespace) var photoPreviewNamespace
    @EnvironmentObject var viewModel: PhotoViewModel

    @State private var offset: CGSize = .zero
    @State private var selected: String?
    @State private var showOverlay = false
    @State private var showTabView = false
    @State private var baseFrameSize: CGSize = CGSize(width: min(UIScreen.main.bounds.width, UIScreen.main.bounds.height), height: min(UIScreen.main.bounds.width, UIScreen.main.bounds.height))
    @State private var isDragging = false

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

                    PhotoView(photo: previewPhoto, quality: .high, contentMode: .fill, onLoad: { image in 
                        print("🔄 image preview loaded: \(image)")
                        baseFrameSize = getBaseFrameSize(image: image)

                    })
                    .frame(width: baseFrameSize.width, height: baseFrameSize.height)
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

     private func getBaseFrameSize(image: UIImage) -> CGSize {
        print("🔄 updateLayout \(image)")

        let imageSize = image.size
        let imageAspectRatio = imageSize.width / imageSize.height

        let containerWidth = UIScreen.main.bounds.width
        let containerHeight = UIScreen.main.bounds.height
        let containerAspectRatio = containerWidth / containerHeight

        let baseFrameWidth: CGFloat =
            imageAspectRatio > containerAspectRatio
            ? containerWidth
            : containerHeight * imageAspectRatio

        let baseFrameHeight: CGFloat =
            imageAspectRatio > containerAspectRatio
            ? containerWidth / imageAspectRatio
            : containerHeight

        return CGSize(width: baseFrameWidth, height: baseFrameHeight)
    }
}
