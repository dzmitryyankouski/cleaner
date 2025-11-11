import Photos
import SwiftUI

// MARK: - Photo Thumbnail Card

/// Карточка с миниатюрой фотографии
struct PhotoThumbnailCard: View {
    @Environment(\.photoPreviewNamespace) var photoPreviewNamespace

    let photo: Photo
    var size: CGSize = CGSize(width: 165, height: 220)
    let isSelected: Bool
    let isPreviewing: Bool
    var onSelectAction: (() -> Void)?

    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var requestID: PHImageRequestID = PHInvalidImageRequestID
    
    private let screenBounds = UIScreen.main.bounds

    func onSelect(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onSelectAction = action
        return copy
    }

    var body: some View {
        if let namespace = photoPreviewNamespace {

            Color.clear
                .overlay {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                }
                .clipped()
                .matchedGeometryEffect(id: photo.id, in: namespace)
                .frame(width: 100, height: 100)
                .onTapGesture {
                    onSelectAction?()
                }
                .zIndex(isPreviewing ? 1 : 0)
                .onAppear {
                    loadImage()
                }


            // ZStack {
            //     VStack {
            //         HStack {
            //             Spacer()
            //             Image(systemName: "photo.on.rectangle.angled")
            //                 .font(.caption)
            //                 .foregroundColor(.white)
            //                 .padding(4)
            //                 .background(Color.blue.opacity(0.8))
            //                 .cornerRadius(4)
            //         }
            //         Spacer()
            //         HStack {
            //             Spacer()
            //             Button(action: {
            //                 onSelectAction?()
            //             }) {
            //                 Image(systemName: isSelected ? "trash.circle.fill" : "circle")
            //                     .font(.title3)
            //                     .foregroundColor(isSelected ? .red : .white)
            //                     .background(Color.black.opacity(0.6))
            //                     .clipShape(Circle())
            //             }
            //         }
            //     }
            //     .padding(8)
            // }
            // .frame(width: size.width, height: size.height)
            // .background(
            //     ZStack {
            //         if let image = image {
            //             Image(uiImage: image)
            //                 .resizable()
            //                 .aspectRatio(contentMode: .fill)
            //                 .cornerRadius(8)
            //         }
            //     }
            //     .matchedGeometryEffect(id: photo.id, in: namespace)
            // )
            // // .drawingGroup()  // Рендерим в Metal для лучшей производительности
            // .onAppear {
            //     loadImage()
            // }
        }
    }

    // MARK: - Overlay View

    // private var overlayView: some View {
    //     VStack {
    //         HStack {
    //             Spacer()
    //             Image(systemName: "photo.on.rectangle.angled")
    //                 .font(.caption)
    //                 .foregroundColor(.white)
    //                 .padding(4)
    //                 .background(Color.blue.opacity(0.8))
    //                 .cornerRadius(4)
    //         }
    //         Spacer()
    //         HStack {
    //             Spacer()
    //             Button(action: {
    //                 onSelectAction?()
    //             }) {
    //                 Image(systemName: isSelected ? "trash.circle.fill" : "circle")
    //                     .font(.title3)
    //                     .foregroundColor(isSelected ? .red : .white)
    //                     .background(Color.black.opacity(0.6))
    //                     .clipShape(Circle())
    //             }
    //         }
    //     }
    //     .padding(8)
    // }

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
        // Не загружаем, если уже загружается или изображение уже загружено
        guard !isLoading && image == nil else { return }

        isLoading = true

        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = false  // Не загружать из iCloud при скролле

        // Сохраняем requestID сразу после создания запроса
        // (requestImage возвращает ID синхронно, callback вызывается асинхронно)
        var capturedRequestID: PHImageRequestID = PHInvalidImageRequestID

        let currentRequestID = PHImageManager.default().requestImage(
            for: photo.asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
        ) { result, _ in
            DispatchQueue.main.async {
                // Проверяем, что запрос еще актуален (не был отменен)
                // Сравниваем сохраненный requestID с захваченным
                if self.requestID == capturedRequestID {
                    self.image = result
                    self.isLoading = false
                }
            }
        }

        capturedRequestID = currentRequestID
        self.requestID = currentRequestID
    }

    private func getFrameSize() -> CGSize {
        let imageSize = image?.size ?? .zero
        let imageAspectRatio = imageSize.width / imageSize.height

        let containerWidth = screenBounds.width
        let containerHeight = screenBounds.height
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
