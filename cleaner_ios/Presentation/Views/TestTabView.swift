import Photos
import SwiftUI

private enum AxisLock {
    case none
    case vertical
    case horizontal
}

struct TestTabView: View {
    @State private var photos: [UIImage] = []
    @State private var isLoading = false
    @State private var show = false
    @State private var selectedIndex: Int?
    @State private var offset: CGSize = .zero
    @State private var isDragging = false
    @State private var verticalGestureMask: GestureMask = .subviews
    @State private var showOverlay = false
    @State private var baseFrameSize: CGSize = UIScreen.main.bounds.size
    @State private var showTabView = false

    @Namespace var namespace
    private let screenBounds = UIScreen.main.bounds

    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Загрузка фото...")
            } else if photos.isEmpty {
                Button("Загрузить 10 фото") {
                    loadPhotos()
                }
            } else {
                VStack {
                    Spacer()

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(photos.indices, id: \.self) { index in
                                Color.clear
                                    .overlay(
                                        Image(uiImage: photos[index])
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    )
                                    .clipped()
                                    .matchedGeometryEffect(id: index, in: namespace)
                                    .frame(width: 100, height: 100)
                                    .onTapGesture {
                                        updateLayout(for: index)

                                        withAnimation(
                                            .spring(response: 0.4, dampingFraction: 0.85)
                                        ) {
                                            show.toggle()
                                            selectedIndex = index
                                        }
                                    }
                                    .zIndex(selectedIndex == index ? 1 : 0)
                            }
                        }
                    }
                    .scrollClipDisabled(true)

                    Spacer()
                }
            }

            if let _selectedIndex = selectedIndex, show {
                ZStack {
                    Color.gray
                        .ignoresSafeArea()
                        .opacity(max(0.6, (0.9 - abs(offset.height) / 1000.0)))

                    if showTabView {
                        TabView(selection: $selectedIndex) {
                            ForEach(photos.indices, id: \.self) { index in
                                Color.clear
                                    .overlay(
                                        Image(uiImage: photos[index])
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                    )
                                    .clipped()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .offset(x: offset.width, y: offset.height)
                                    .scaleEffect(1 - (abs(offset.height) / 1000))
                                    .animation(.interactiveSpring(response: 0.1, dampingFraction: 0.95), value: offset)
                                    .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .simultaneousGesture(overlayDragGesture())
                        .opacity(showOverlay ? 0 : 1)
                    }

                    Color.clear
                        .overlay(
                            Image(uiImage: photos[_selectedIndex])
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        )
                        .clipped()
                        .matchedGeometryEffect(id: _selectedIndex, in: namespace)
                        .frame(width: baseFrameSize.width * (1 - (abs(offset.height) / 1000)), height: baseFrameSize.height * (1 - (abs(offset.height) / 1000)))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .offset(x: offset.width, y: offset.height)
                        .animation(.interactiveSpring(response: 0.1, dampingFraction: 0.95), value: offset)
                        .opacity(showOverlay ? 1 : 0)
                        .gesture(overlayDragGesture())
                    
                }
                .zIndex(2)
                .onAppear {
                    showOverlay = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        showOverlay = false
                        showTabView = true
                    }
                }
                .onChange(of: selectedIndex) { newValue in
                    updateLayout(for: newValue)
                }
            }
        }
    }

    private func overlayDragGesture() -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                isDragging = isDragging || abs(value.translation.width) < abs(value.translation.height)

                if show && isDragging {
                    showOverlay = true
                    offset = value.translation
                }
            }
            .onEnded { value in
                isDragging = false

                if show && abs(value.translation.height) < 100 && abs(value.predictedEndTranslation.height) < 250 {
                    offset = .zero

                    withAnimation(.spring(response: 0.1, dampingFraction: 0.95)) {
                        showOverlay = false
                    }
                } else {
                    showTabView = false

                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        offset = .zero
                        show = false
                    }
                }
            }
    }

    private func loadPhotos() {
        isLoading = true
        photos.removeAll()

        // Запрашиваем доступ к фото
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                DispatchQueue.main.async {
                    isLoading = false
                }
                return
            }

            // Получаем последние 10 фото
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = 10

            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)

            let imageManager = PHImageManager.default()
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = false
            requestOptions.deliveryMode = .highQualityFormat

            var loadedPhotos: [UIImage] = []
            let group = DispatchGroup()

            fetchResult.enumerateObjects { asset, _, _ in
                group.enter()

                imageManager.requestImage(
                    for: asset,
                    targetSize: CGSize(width: 300, height: 300),
                    contentMode: .aspectFill,
                    options: requestOptions
                ) { image, _ in
                    if let image = image {
                        loadedPhotos.append(image)
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                self.photos = loadedPhotos
                self.isLoading = false
            }
        }
    }

    private func updateLayout(for index: Int?) {
        guard let index, photos.indices.contains(index) else {
            return
        }

        let imageSize = photos[index].size
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

        baseFrameSize = CGSize(width: baseFrameWidth, height: baseFrameHeight)
    }
}
