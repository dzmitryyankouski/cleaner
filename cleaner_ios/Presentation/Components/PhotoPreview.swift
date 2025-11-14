import Photos
import SwiftUI

struct PhotoPreview: View {
    @Environment(\.photoPreviewNamespace) var photoPreviewNamespace
    @EnvironmentObject var viewModel: PhotoViewModel

    @State private var offset: CGSize = .zero
    @State private var selected: Int?
    @State private var showOverlay = false
    @State private var showTabView = false
    @State private var baseFrameSize: CGSize = CGSize(width: min(UIScreen.main.bounds.width, UIScreen.main.bounds.height), height: min(UIScreen.main.bounds.width, UIScreen.main.bounds.height))
    @State private var isDragging = false
    
    private var previewPhotoIndexBinding: Binding<Int> {
        Binding(
            get: { viewModel.previewPhoto?.index ?? 0 },
            set: { newValue in
                viewModel.previewPhoto?.index = newValue
            }
        )
    }

    var body: some View {
        Group {
            // if let namespace = photoPreviewNamespace, let previewPhoto = viewModel.previewPhoto, previewPhoto.show == true {
                
            //     ZStack {
            //         Color.white
            //             .ignoresSafeArea()
            //             .opacity(max(0.6, (0.9 - abs(offset.height) / 1000.0)))

            //         if showTabView {
            //             TabView(selection: previewPhotoIndexBinding) {
            //                 ForEach(Array(previewPhoto.items.enumerated()), id: \.element.id) { index, photo in
            //                     PhotoView(photo: photo, quality: .high, contentMode: .fit, matchedGeometry: false)
            //                         .frame(maxWidth: .infinity, maxHeight: .infinity)
            //                         .ignoresSafeArea()
            //                         .tag(index)
            //                 }
            //             }
            //             .tabViewStyle(.page(indexDisplayMode: .never))
            //             .ignoresSafeArea()
            //             .simultaneousGesture(overlayDragGesture())
            //             .opacity(showOverlay ? 0 : 1)
            //         }

            //         PhotoView(photo: previewPhoto.items[previewPhoto.index], quality: .high, contentMode: .fill, onLoad: { image in 
            //             baseFrameSize = getBaseFrameSize(image: image)
            //         })
            //         .frame(width: baseFrameSize.width * (1 - (abs(offset.height) / 1000)), height: baseFrameSize.height * (1 - (abs(offset.height) / 1000)))
            //         .frame(maxWidth: .infinity, maxHeight: .infinity)
            //         .offset(x: offset.width, y: offset.height)
            //         .opacity(showOverlay ? 1 : 0)
            //         .gesture(overlayDragGesture())
            //         .ignoresSafeArea()
            //         .id(previewPhoto.index)
            //     }
            //     .zIndex(2)
            //     .onAppear {    
            //         showOverlay = true

            //          DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            //             showTabView = true
            //         }

            //         DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            //             showOverlay = false
            //         }
            //     }
            // }
        }
    }

    //  private func overlayDragGesture() -> some Gesture {
    //     DragGesture(minimumDistance: 0)
    //         .onChanged { value in
    //             isDragging = isDragging || abs(value.translation.width) < abs(value.translation.height)

    //             if viewModel.previewPhoto != nil && isDragging {
    //                 showOverlay = true
    //                 offset = value.translation
    //             }
    //         }
    //         .onEnded { value in
    //             isDragging = false

    //             if viewModel.previewPhoto != nil && abs(value.translation.height) < 100 && abs(value.predictedEndTranslation.height) < 250 {
    //                 offset = .zero
    //                 showOverlay = false
    //             } else {
    //                 showTabView = false

    //                 withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
    //                     offset = .zero
    //                     viewModel.previewPhoto?.show = false
    //                     selected = nil
    //                 }
    //             }
    //         }
    // }

    // private func getBaseFrameSize(image: UIImage) -> CGSize {
    //     return getBaseFrameSize(imageSize: image.size)
    // }
    
    // private func getBaseFrameSize(imageSize: CGSize) -> CGSize {
    //     let imageAspectRatio = imageSize.width / imageSize.height

    //     let containerWidth = UIScreen.main.bounds.width
    //     let containerHeight = UIScreen.main.bounds.height
    //     let containerAspectRatio = containerWidth / containerHeight

    //     let baseFrameWidth: CGFloat =
    //         imageAspectRatio > containerAspectRatio
    //         ? containerWidth
    //         : containerHeight * imageAspectRatio

    //     let baseFrameHeight: CGFloat =
    //         imageAspectRatio > containerAspectRatio
    //         ? containerWidth / imageAspectRatio
    //         : containerHeight

    //     return CGSize(width: baseFrameWidth, height: baseFrameHeight)
    // }
}
