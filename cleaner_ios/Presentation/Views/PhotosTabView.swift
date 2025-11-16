import SwiftUI
import SwiftData

struct PhotosTabView: View {

    @Environment(\.photoLibrary) var photoLibrary
    @State private var selectedTab = 0
    @State private var showSettings: Bool = false

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
                            //PickerHeader(selectedTab: $selectedTab, tabs: tabs)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Фотографии")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape") {
                        showSettings.toggle()
                    }
                    .popover(isPresented: $showSettings) {
                        SettingsTabView()
                    }
                }
            }
            .refreshable {
                photoLibrary?.reset()

                await photoLibrary?.loadPhotos()
            }
        }
    }
}

struct SimilarPhotosView: View {
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
    @Environment(\.photoLibrary) var photoLibrary

    var body: some View {
        if photoLibrary?.indexing ?? false {
            ProgressLoadingView(
                title: "Индексация фотографий",
                current: photoLibrary?.indexed ?? 0,
                total: photoLibrary?.total ?? 0
            )
            .padding(.horizontal)
        } else if photoLibrary?.duplicatesGroups.isEmpty ?? true {
            EmptyStateView(
                icon: "doc.on.doc",
                title: "Дубликаты не найдены",
                message: "В вашей галерее нет точных копий фотографий"
            )
        } else {
            LazyVStack(alignment: .leading, spacing: 16) {
                StatisticCardView(statistics: [
                    .init(label: "Найдено групп", value: "\(photoLibrary?.duplicatesGroups.count ?? 0)", alignment: .leading),
                    .init(label: "Фото в группах", value: "\(photoLibrary?.duplicatesPhotos.count ?? 0)", alignment: .center),
                    .init(label: "Общий размер", value: FileSize(bytes: photoLibrary?.duplicatesPhotosFileSize ?? 0).formatted, alignment: .trailing),
                ])
                .padding(.horizontal)

                LazyVStack(spacing: 20) {
                    ForEach(photoLibrary?.duplicatesGroups ?? [], id: \.id) { group in
                        PhotoGroupRowView(group: group)
                    }
                }
                .padding(.top)
            }
        }
    }
}

struct ScreenshotsView: View {
    @Environment(\.photoLibrary) var photoLibrary

    var body: some View {
        if photoLibrary?.screenshots.isEmpty ?? true {
            EmptyStateView(
                icon: "camera.viewfinder",
                title: "Скриншоты не найдены",
                message: "В вашей галерее нет скриншотов"
            )
        } else {
            PhotoGridView(photos: photoLibrary?.screenshots ?? [])
        }
    }
}

struct PhotoGroupRowView: View {
    @Environment(\.photoPreview) var photoPreview

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
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                    photoPreview?.show(photos: group.photos, item: photo)
                                }
                            }
                            .id(photo.id)
                            .zIndex(photoPreview?.photo?.id == photo.id ? 10 : 0)
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
    let photos: [PhotoModel]

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 12
        ) {
            ForEach(photos, id: \.id) { photo in
                PhotoThumbnailCard(photo: photo)
                    .id(photo.id)
            }
        }
        .padding(.horizontal)
    }
}
