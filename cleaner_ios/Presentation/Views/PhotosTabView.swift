import SwiftUI
import SwiftData

struct PhotosTabView: View {

    @EnvironmentObject var viewModel: PhotoViewModel
    @State private var selectedTab = 0

    private let tabs = ["Серии", "Копии", "Скриншоты"]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView {
                    LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                        Section {
                            switch selectedTab {
                            case 0:
                                SimilarPhotosView()
                            case 1:
                                DuplicatesView()
                            case 2:
                                ScreenshotsView()
                            default:
                                SimilarPhotosView()
                            }
                        } header: {
                            PickerHeader(selectedTab: $selectedTab, tabs: tabs)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Фотографии")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape") {
                        //
                    }
                }
            }
            .refreshable {
                await viewModel.refreshPhotos()
            }
        }
    }
}

struct SimilarPhotosView: View {
    @EnvironmentObject var viewModel: PhotoViewModel
    @Environment(\.photoLibrary) var photoLibrary

    var body: some View {
        if photoLibrary?.indexing ?? false {
            ProgressLoadingView(
                title: "Индексация фотографий",
                current: photoLibrary?.indexed ?? 0,
                total: photoLibrary?.total ?? 0
            )
            .padding(.horizontal)
        } else if photoLibrary?.similarGroups.isEmpty ?? true {
            EmptyStateView(
                icon: "photo.on.rectangle.angled",
                title: "Похожие фотографии не найдены",
                message: "Попробуйте выбрать другие изображения"
            )
        } else {
            LazyVStack(alignment: .leading, spacing: 16) {
                StatisticCardView(statistics: [
                    .init(label: "Найдено групп", value: "\(photoLibrary?.similarGroups.count ?? 0)", alignment: .leading),
                    .init(label: "Фото в группах", value: "\(photoLibrary?.similarPhotos.count ?? 0)", alignment: .center),
                    .init(label: "Общий размер", value: FileSize(bytes: photoLibrary?.similarPhotosFileSize ?? 0).formatted, alignment: .trailing),
                ])
                .padding(.horizontal)

                LazyVStack(spacing: 20) {
                    ForEach(photoLibrary?.similarGroups ?? [], id: \.id) { group in
                        PhotoGroupRowView(group: group)
                    }
                }
                .padding(.top)
            }
        }
    }
}

struct DuplicatesView: View {
    @EnvironmentObject var viewModel: PhotoViewModel

    private var filteredGroups: [MediaGroup<Photo>] {
        viewModel.groupsDuplicates.filter { $0.count > 1 }
    }

    var body: some View {
        // if viewModel.indexing {
        //     ProgressLoadingView(
        //         title: "Индексация фотографий",
        //         current: viewModel.indexed,
        //         total: viewModel.total
        //     )
        //     .padding(.horizontal)
        // } else if filteredGroups.isEmpty {
        //     EmptyStateView(
        //         icon: "doc.on.doc",
        //         title: "Дубликаты не найдены",
        //         message: "В вашей галерее нет точных копий фотографий"
        //     )
        // } else {
        //     LazyVStack(alignment: .leading, spacing: 16) {
        //         StatisticCardView(statistics: [
        //             .init(label: "Найдено групп", value: "\(filteredGroups.count)", alignment: .leading),
        //             .init(label: "Фото в группах", value: "\(totalPhotosCount)", alignment: .center),
        //             .init(label: "Общий размер", value: totalFileSize, alignment: .trailing),
        //         ])
        //         .padding(.horizontal)

        //         LazyVStack(spacing: 20) {
        //             ForEach(Array(filteredGroups.enumerated()), id: \.offset) { index, group in
        //                 PhotoGroupRowView(
        //                     groupIndex: index,
        //                     group: group,
        //                     onPreviewPhoto: { index in
        //                         print("Preview photo: \(index)")
        //                     }
        //                 )
        //             }
        //         }
        //         .padding(.top)
        //     }
        // }
    }

    private var totalPhotosCount: Int {
        filteredGroups.reduce(0) { $0 + $1.count }
    }

    private var totalFileSize: String {
        let bytes = filteredGroups.flatMap { $0.items }.reduce(0) { $0 + $1.fileSize.bytes }
        return FileSize(bytes: bytes).formatted
    }
}

// MARK: - Screenshots View

struct ScreenshotsView: View {
    @EnvironmentObject var viewModel: PhotoViewModel

    private var screenshots: [Photo] {
        viewModel.photos.filter { $0.isScreenshot() }
    }

    var body: some View {
        // if screenshots.isEmpty {
        //     EmptyStateView(
        //         icon: "camera.viewfinder",
        //         title: "Скриншоты не найдены",
        //         message: "В вашей галерее нет скриншотов"
        //     )
        // } else {
        //     PhotoGridView(photos: screenshots)
        // }
    }
}

struct PhotoGroupRowView: View {
    let group: PhotoGroupModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Группа (\(group.photos.count) фото)")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(group.photos, id: \.id) { photo in
                        PhotoThumbnailCard(photo: photo)
                        .id(photo.id)
                        // .zIndex(viewModel.previewPhoto?.index == index ? 10 : 0)
                    }
                }
                .padding(.horizontal)
            }
            .scrollClipDisabled(true)
        }
    }
}

// MARK: - Photo Grid View

struct PhotoGridView: View {
    let photos: [Photo]
    @EnvironmentObject var viewModel: PhotoViewModel

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 12
        ) {
            ForEach(photos) { photo in
                // GeometryReader { geometry in
                //     PhotoThumbnailCard(
                //         photo: photo,
                //         size: CGSize(width: 120, height: 160),
                //         isSelected: viewModel.selectedPhotosForDeletion.contains(photo.index),
                //         isPreviewing: viewModel.previewPhoto?.id == photo.id
                //     )
                //     .onSelect {
                //         viewModel.togglePhotoSelection(for: photo)
                //     }
                //     .id(photo.id)
                //     .onTapGesture {
                //         viewModel.previewPhoto = photo

                //         withAnimation(.spring(response: 0.3, dampingFraction: 1)) {
                //             viewModel.showPreviewModel = true
                //         }
                //     }
                // }
                // .frame(width: 120, height: 160)
            }
        }
        .padding(.horizontal)
    }
}
