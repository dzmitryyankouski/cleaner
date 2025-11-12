import SwiftUI

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
                    Button("Search", systemImage: "magnifyingglass") {
                        //
                    }
                }
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
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

    private var filteredGroups: [MediaGroup<Photo>] {
        viewModel.groupsSimilar.filter { $0.count > 1 }
    }

    var body: some View {
        if viewModel.indexing {
            ProgressLoadingView(
                title: "Индексация фотографий",
                current: viewModel.indexed,
                total: viewModel.total
            )
            .padding(.horizontal)
        } else if filteredGroups.isEmpty {
            EmptyStateView(
                icon: "photo.on.rectangle.angled",
                title: "Похожие фотографии не найдены",
                message: "Попробуйте выбрать другие изображения"
            )
        } else {
            LazyVStack(alignment: .leading, spacing: 16) {
                StatisticCardView(statistics: [
                    .init(label: "Найдено групп", value: "\(filteredGroups.count)", alignment: .leading),
                    .init(label: "Фото в группах", value: "\(totalPhotosCount)", alignment: .center),
                    .init(label: "Общий размер", value: totalFileSize, alignment: .trailing),
                ])
                .padding(.horizontal)

                LazyVStack(spacing: 20) {
                    ForEach(Array(filteredGroups.enumerated()), id: \.offset) { index, group in
                        PhotoGroupRowView(
                            groupIndex: index,
                            group: group,
                            onPreviewPhoto: { index in
                                print("Preview photo: \(index)")
                                viewModel.previewPhoto(index: index, items: group.items)
                            }
                        )
                    }
                }
                .padding(.top)
            }
        }
    }

    private var totalPhotosCount: Int {
        //filteredGroups.reduce(0) { $0 + $1.count }
        return 0
    }

    private var totalFileSize: String {
        // let bytes = filteredGroups.flatMap { $0.items }.reduce(0) { $0 + $1.fileSize.bytes }
        // return FileSize(bytes: bytes).formatted
        return "0"
    }
}

struct DuplicatesView: View {
    @EnvironmentObject var viewModel: PhotoViewModel

    private var filteredGroups: [MediaGroup<Photo>] {
        viewModel.groupsDuplicates.filter { $0.count > 1 }
    }

    var body: some View {
        if viewModel.indexing {
            ProgressLoadingView(
                title: "Индексация фотографий",
                current: viewModel.indexed,
                total: viewModel.total
            )
            .padding(.horizontal)
        } else if filteredGroups.isEmpty {
            EmptyStateView(
                icon: "doc.on.doc",
                title: "Дубликаты не найдены",
                message: "В вашей галерее нет точных копий фотографий"
            )
        } else {
            LazyVStack(alignment: .leading, spacing: 16) {
                StatisticCardView(statistics: [
                    .init(label: "Найдено групп", value: "\(filteredGroups.count)", alignment: .leading),
                    .init(label: "Фото в группах", value: "\(totalPhotosCount)", alignment: .center),
                    .init(label: "Общий размер", value: totalFileSize, alignment: .trailing),
                ])
                .padding(.horizontal)

                LazyVStack(spacing: 20) {
                    ForEach(Array(filteredGroups.enumerated()), id: \.offset) { index, group in
                        PhotoGroupRowView(
                            groupIndex: index,
                            group: group,
                            onPreviewPhoto: { index in
                                print("Preview photo: \(index)")
                            }
                        )
                    }
                }
                .padding(.top)
            }
        }
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
        if screenshots.isEmpty {
            EmptyStateView(
                icon: "camera.viewfinder",
                title: "Скриншоты не найдены",
                message: "В вашей галерее нет скриншотов"
            )
        } else {
            PhotoGridView(photos: screenshots)
        }
    }
}

struct PhotoGroupRowView: View {
    @EnvironmentObject var viewModel: PhotoViewModel
    
    let groupIndex: Int
    let group: MediaGroup<Photo>
    let onPreviewPhoto: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Группа \(groupIndex + 1) (\(group.count) фото)")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(group.items.enumerated()), id: \.element.id) { index, photo in
                        PhotoThumbnailCard(
                            photo: photo,
                            onPreviewPhoto: {
                                onPreviewPhoto(index)
                            }
                        )
                        .id(photo.id)
                        .zIndex(viewModel.previewPhoto?.index == index ? 10 : 0)
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
