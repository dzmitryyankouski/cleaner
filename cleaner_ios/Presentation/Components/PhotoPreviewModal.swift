import Photos
import SwiftUI

struct PhotoPreviewModal: View {
    @Environment(\.photoPreview) var photoPreview
    @Environment(\.photoPreviewNamespace) var photoPreviewNamespace

    @State private var offset: CGSize = .zero
    @State private var showOverlay = false
    @State private var showTabView = false
    @State private var isDragging = false
    
    private var previewPhotoIndexBinding: Binding<Int> {
        Binding(
            get: { photoPreview?.index ?? 0 },
            set: { newValue in
                photoPreview?.index = newValue
            }
        )
    }

    var body: some View {
        Group {
            if let namespace = photoPreviewNamespace, 
               let previewPhoto = photoPreview, 
               previewPhoto.isPresented == true,
               let currentIndex = previewPhoto.index,
               currentIndex >= 0 && currentIndex < previewPhoto.photos.count {
                
                ZStack {
                    Color.white
                        .ignoresSafeArea()
                        .opacity(max(0.6, (1 - abs(offset.height) / 1000.0)))

                    PhotoView(photo: previewPhoto.photos[currentIndex], quality: .high, contentMode: .fill)
                        .frame(
                            width: CGFloat(previewPhoto.photos[currentIndex].fullScreenFrameWidth) * (1 - (abs(offset.height) / 1000.0)), 
                            height: CGFloat(previewPhoto.photos[currentIndex].fullScreenFrameHeight) * (1 - (abs(offset.height) / 1000.0))
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .offset(x: offset.width, y: offset.height)
                        .opacity(showOverlay ? 1 : 0)
                        .gesture(overlayDragGesture())
                        .ignoresSafeArea()
                        .id(previewPhoto.photos[currentIndex].id)

                    if showTabView {
                        TabView(selection: previewPhotoIndexBinding) {
                            ForEach(Array(previewPhoto.photos.enumerated()), id: \.element.id) { index, photo in
                                PhotoView(photo: photo, quality: .high, contentMode: .fit, matchedGeometry: false)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .ignoresSafeArea()
                                    .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .ignoresSafeArea()
                        .simultaneousGesture(overlayDragGesture())
                        .opacity(showOverlay ? 0 : 1)
                        .zIndex(showOverlay ? 1 : 2)
                    }
                }
                .zIndex(2)
                .onAppear {    
                    showOverlay = true

                     DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        showTabView = true
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showOverlay = false
                    }
                }
            }
        }
    }

     private func overlayDragGesture() -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                isDragging = isDragging || abs(value.translation.width) < abs(value.translation.height)

                if photoPreview?.isPresented == true && isDragging {
                    showOverlay = true
                    offset = value.translation
                }
            }
            .onEnded { value in
                isDragging = false

                if photoPreview?.isPresented == true && abs(value.translation.height) < 100 && abs(value.predictedEndTranslation.height) < 250 {
                    offset = .zero
                    showOverlay = false
                } else {
                    showTabView = false

                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        offset = .zero
                        photoPreview?.hide()
                    }
                }
            }
    }
}
