import SwiftUI

// MARK: - Photos Tab View

struct PhotosTabView: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: PhotoViewModel
    @State private var selectedTab = 0
    
    private let tabs = ["Серии", "Копии", "Скриншоты", "Размытые"]
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Статистика или прогресс
                headerView
                
                // Сегментированный контрол
                if !viewModel.indexing && !viewModel.photos.isEmpty {
                    Picker("Табы", selection: $selectedTab) {
                        ForEach(tabs.indices, id: \.self) { index in
                            Text(tabs[index]).tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                // Контент таба
                tabContent
            }
            .navigationTitle("Фотографии")
            .navigationBarTitleDisplayMode(.inline)
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
                    value: "\(viewModel.totalPhotosCount) / \(viewModel.selectedPhotosForDeletion.count)",
                    alignment: .leading
                ),
                .init(
                    label: "Размер",
                    value: "\(viewModel.formattedTotalFileSize) / \(viewModel.formattedSelectedFileSize)",
                    alignment: .trailing
                )
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
        case 3:
            BlurredPhotosView(viewModel: viewModel)
        default:
            SimilarPhotosView(viewModel: viewModel)
        }
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
            LoadingView(
                title: "Поиск похожих изображений...",
                message: "Анализ фотографий и создание групп"
            )
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
            LoadingView(
                title: "Поиск дубликатов...",
                message: "Анализ фотографий на наличие точных копий"
            )
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
        viewModel.photos.filter { $0.isScreenshot }
    }
    
    var body: some View {
        if viewModel.indexing {
            LoadingView(
                title: "Поиск скриншотов...",
                message: "Анализ фотографий на наличие скриншотов"
            )
        } else if screenshots.isEmpty {
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

// MARK: - Blurred Photos View

struct BlurredPhotosView: View {
    @ObservedObject var viewModel: PhotoViewModel
    @State private var blurredPhotos: [Photo] = []
    @State private var isLoading = false
    
    var body: some View {
        if viewModel.indexing {
            LoadingView(
                title: "Поиск размытых фотографий...",
                message: "Анализ фотографий на наличие размытых изображений"
            )
        } else if isLoading {
            LoadingView(
                title: "Поиск размытых фотографий..."
            )
        } else if blurredPhotos.isEmpty {
            EmptyStateView(
                icon: "eye.slash",
                title: "Размытые фотографии не найдены",
                message: "В вашей галерее нет размытых изображений"
            )
        } else {
            PhotoGridView(
                photos: blurredPhotos,
                viewModel: viewModel
            )
            .onAppear {
                loadBlurredPhotos()
            }
            .onChange(of: viewModel.indexing) { _, newValue in
                if !newValue {
                    loadBlurredPhotos()
                }
            }
        }
    }
    
    private func loadBlurredPhotos() {
        guard !viewModel.indexing && !viewModel.photos.isEmpty else { return }
        
        isLoading = true
        Task {
            let photos = await viewModel.getBlurredPhotos()
            await MainActor.run {
                self.blurredPhotos = photos
                self.isLoading = false
            }
        }
    }
}

// MARK: - Photo Groups Scroll View

struct PhotoGroupsScrollView: View {
    let groups: [MediaGroup<Photo>]
    @ObservedObject var viewModel: PhotoViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
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
    }
    
    private var groupStatistics: some View {
        StatisticCardView(statistics: [
            .init(label: "Найдено групп", value: "\(groups.count)", alignment: .leading),
            .init(label: "Фото в группах", value: "\(totalPhotosCount)", alignment: .center),
            .init(label: "Общий размер", value: totalFileSize, alignment: .trailing)
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
                HStack(spacing: 12) {
                    ForEach(group.items) { photo in
                        PhotoThumbnailCard(
                            photo: photo,
                            isSelected: viewModel.selectedPhotosForDeletion.contains(photo.index),
                            onToggle: {
                                viewModel.togglePhotoSelection(for: photo)
                            }
                        )
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
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(photos) { photo in
                    PhotoThumbnailCard(
                        photo: photo,
                        size: CGSize(width: 120, height: 160),
                        isSelected: viewModel.selectedPhotosForDeletion.contains(photo.index),
                        onToggle: {
                            viewModel.togglePhotoSelection(for: photo)
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

