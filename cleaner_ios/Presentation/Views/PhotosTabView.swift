import SwiftUI

// MARK: - Photos Tab View

struct PhotosTabView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: PhotoViewModel
    @State private var selectedTab = 0

    private let tabs = ["Серии", "Копии", "Скриншоты"]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView {
                    LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                        Section {
                            tabContent
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

    // MARK: - Header View

    @ViewBuilder
    private var headerView: some View {
        if viewModel.indexing {
            ProgressLoadingView(
                title: "Индексация фотографий",
                current: viewModel.indexed,
                total: viewModel.total
            )
            .padding(.horizontal)
        } else if !viewModel.photos.isEmpty {
            StatisticCardView(statistics: [
                .init(
                    label: "Фотографии",
                    value:
                        "\(viewModel.totalPhotosCount) / \(viewModel.selectedPhotosForDeletion.count)",
                    alignment: .leading
                ),
                .init(
                    label: "Размер",
                    value:
                        "\(viewModel.formattedTotalFileSize) / \(viewModel.formattedSelectedFileSize)",
                    alignment: .trailing
                ),
            ])
            .padding(.horizontal)
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0:
            SimilarPhotosView(viewModel: viewModel)
        case 1:
            DuplicatesView(viewModel: viewModel)
        case 2:
            ScreenshotsView(viewModel: viewModel)
        default:
            SimilarPhotosView(viewModel: viewModel)
        }
    }
}

struct PickerHeader: View {
    @Binding var selectedTab: Int
    let tabs: [String]

    var body: some View {
        VStack(spacing: 0) {
            Picker("Табы", selection: $selectedTab) {
                ForEach(tabs.indices, id: \.self) { index in
                    Text(tabs[index])
                        .padding(.vertical, 2)
                        .tag(index)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(maxWidth: 300)
            .glassEffect()
        }
    }
}

struct Info: View {
    @ObservedObject var viewModel: PhotoViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("\(viewModel.totalPhotosCount) / \(viewModel.selectedPhotosForDeletion.count)")
                Text("\(viewModel.formattedTotalFileSize) / \(viewModel.formattedSelectedFileSize)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(25)
        }
        .padding(.horizontal)
    }
}

// MARK: - Similar Photos View

struct SimilarPhotosView: View {
    @ObservedObject var viewModel: PhotoViewModel

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
            PhotoGroupsScrollView(
                groups: filteredGroups,
                viewModel: viewModel
            )
        }
    }
}

// MARK: - Duplicates View

struct DuplicatesView: View {
    @ObservedObject var viewModel: PhotoViewModel

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
            PhotoGroupsScrollView(
                groups: filteredGroups,
                viewModel: viewModel
            )
        }
    }
}

// MARK: - Screenshots View

struct ScreenshotsView: View {
    @ObservedObject var viewModel: PhotoViewModel

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
            PhotoGridView(
                photos: screenshots,
                viewModel: viewModel
            )
        }
    }
}

// MARK: - Photo Groups Scroll View

struct PhotoGroupsScrollView: View {
    let groups: [MediaGroup<Photo>]
    @ObservedObject var viewModel: PhotoViewModel

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            // Статистика групп
            groupStatistics

            // Группы фотографий
            LazyVStack(spacing: 20) {
                ForEach(Array(groups.enumerated()), id: \.offset) { index, group in
                    PhotoGroupRowView(
                        groupIndex: index,
                        group: group,
                        viewModel: viewModel
                    )
                }
            }
            .padding(.top)
        }
    }

    private var groupStatistics: some View {
        StatisticCardView(statistics: [
            .init(label: "Найдено групп", value: "\(groups.count)", alignment: .leading),
            .init(label: "Фото в группах", value: "\(totalPhotosCount)", alignment: .center),
            .init(label: "Общий размер", value: totalFileSize, alignment: .trailing),
        ])
        .padding(.horizontal)
    }

    private var totalPhotosCount: Int {
        groups.reduce(0) { $0 + $1.count }
    }

    private var totalFileSize: String {
        let bytes = groups.flatMap { $0.items }.reduce(0) { $0 + $1.fileSize.bytes }
        return FileSize(bytes: bytes).formatted
    }
}

// MARK: - Photo Group Row View

struct PhotoGroupRowView: View {
    let groupIndex: Int
    let group: MediaGroup<Photo>
    
    @ObservedObject var viewModel: PhotoViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Группа \(groupIndex + 1) (\(group.count) фото)")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(group.items) { photo in
                        PhotoThumbnailCard(
                            photo: photo,
                            isSelected: viewModel.selectedPhotosForDeletion.contains(photo.index),
                            isPreviewing: viewModel.previewPhoto?.id == photo.id
                        )
                        .onSelect {
                            viewModel.togglePhotoSelection(for: photo)
                        }
                        .onTapGesture {
                            viewModel.previewPhoto = photo

                            withAnimation(.spring(response: 3, dampingFraction: 1)) {
                                viewModel.showPreviewModel = true
                            }
                        }
                        .id(photo.id)
                        .frame(width: 165, height: 220)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Photo Grid View

struct PhotoGridView: View {
    let photos: [Photo]
    @ObservedObject var viewModel: PhotoViewModel

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 12
        ) {
            ForEach(photos) { photo in
                GeometryReader { geometry in
                    PhotoThumbnailCard(
                        photo: photo,
                        size: CGSize(width: 120, height: 160),
                        isSelected: viewModel.selectedPhotosForDeletion.contains(photo.index),
                        isPreviewing: viewModel.previewPhoto?.id == photo.id
                    )
                    .onSelect {
                        viewModel.togglePhotoSelection(for: photo)
                    }
                    .id(photo.id)
                    .onTapGesture {
                        viewModel.previewPhoto = photo

                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            viewModel.showPreviewModel = true
                        }
                    }
                }
                .frame(width: 120, height: 160)
            }
        }
        .padding(.horizontal)
    }
}
