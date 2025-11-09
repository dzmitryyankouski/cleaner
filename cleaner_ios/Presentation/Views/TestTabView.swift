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

    @Namespace var namespace

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
                                        withAnimation(.spring(response: 0.3, dampingFraction: 1)) {
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

                    HStack {
                        TabView(selection: $selectedIndex) {
                            ForEach(photos.indices, id: \.self) { index in
                                GeometryReader { geometry in
                                    let imageSize = photos[index].size
                                    let imageAspectRatio = imageSize.width / imageSize.height
                                    let containerAspectRatio =
                                        geometry.size.width / geometry.size.height

                                    let baseFrameWidth: CGFloat =
                                        imageAspectRatio > containerAspectRatio
                                        ? geometry.size.width
                                        : geometry.size.height * imageAspectRatio

                                    let baseFrameHeight: CGFloat =
                                        imageAspectRatio > containerAspectRatio
                                        ? geometry.size.width / imageAspectRatio
                                        : geometry.size.height

                                    let frameWidth =
                                        max(0.8, (1 - abs(offset.height) / 1000.0)) * baseFrameWidth
                                    let frameHeight =
                                        max(0.8, (1 - abs(offset.height) / 1000.0))
                                        * baseFrameHeight

                                    Color.clear
                                        .overlay(
                                            Image(uiImage: photos[index])
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        )
                                        .clipped()
                                        .if(index == _selectedIndex) { view in
                                            view.matchedGeometryEffect(id: index, in: namespace)
                                        }
                                        .frame(width: frameWidth, height: frameHeight)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .offset(x: offset.width, y: offset.height)
                                }
                                .tag(index)
                                .opacity(index != _selectedIndex && isDragging ? 0 : 1)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    isDragging = isDragging || abs(value.translation.width) < abs(value.translation.height)

                                    if show && isDragging {
                                        withAnimation(.spring(response: 0.1, dampingFraction: 0.95)) {
                                            offset = value.translation
                                        }
                                    }
                                }
                                 .onEnded { _ in
                                    withAnimation(.spring(response: 0.3, dampingFraction: 1)) {
                                        show = show && abs(offset.height) < 100
                                        offset = .zero
                                        isDragging = false
                                    }
                                }
                            )
                    }


                    // GeometryReader { geometry in
                    //     let imageSize = photos[index].size
                    //     let imageAspectRatio = imageSize.width / imageSize.height
                    //     let containerAspectRatio = geometry.size.width / geometry.size.height

                    //     let baseFrameWidth: CGFloat =
                    //         imageAspectRatio > containerAspectRatio
                    //         ? geometry.size.width
                    //         : geometry.size.height * imageAspectRatio

                    //     let baseFrameHeight: CGFloat =
                    //         imageAspectRatio > containerAspectRatio
                    //         ? geometry.size.width / imageAspectRatio
                    //         : geometry.size.height

                    //     let frameWidth = max(0.8, (1 - abs(offset.height) / 1000.0)) * baseFrameWidth
                    //     let frameHeight = max(0.8, (1 - abs(offset.height) / 1000.0)) * baseFrameHeight

                    //     Color.clear
                    //         .overlay(
                    //             Image(uiImage: photos[index])
                    //                 .resizable()
                    //                 .aspectRatio(contentMode: .fill)
                    //         )
                    //         .clipped()
                    //         .matchedGeometryEffect(id: index, in: namespace)
                    //         .frame(width: frameWidth, height: frameHeight)
                    //         .frame(maxWidth: .infinity, maxHeight: .infinity)
                    //         .offset(x: offset.width, y: offset.height)
                            // .gesture(
                            //     DragGesture(minimumDistance: 0)
                            //         .onChanged { value in
                            //             isDragging = isDragging || abs(value.translation.width) < abs(value.translation.height)

                            //             if show && isDragging {
                            //                 withAnimation(
                            //                     .spring(response: 0.1, dampingFraction: 0.95)
                            //                 ) {
                            //                     offset = value.translation
                            //                 }
                            //             }
                            //         }
                            //         .onEnded { value in
                            //             withAnimation(.spring(response: 0.3, dampingFraction: 1))
                            //             {
                            //                 show = show && abs(offset.height) < 100
                            //                 offset = .zero
                            //                 isDragging = false
                            //             }
                            //         }
                            // )
                    // }
                    // .drawingGroup()
                }
                .zIndex(2)
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
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
