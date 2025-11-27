import SwiftUI
import SwiftData

struct PhotoGroupNavigationItem: Hashable {
    let photos: [PhotoModel]
    let currentPhotoId: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(photos.map { $0.id }.joined())
        hasher.combine(currentPhotoId)
    }
    
    static func == (lhs: PhotoGroupNavigationItem, rhs: PhotoGroupNavigationItem) -> Bool {
        lhs.photos.map { $0.id } == rhs.photos.map { $0.id } && lhs.currentPhotoId == rhs.currentPhotoId
    }
}

struct PhotosTabView: View {

    @Environment(\.photoLibrary) var photoLibrary
    @State private var selectedTab = 0
    @State private var showSettings: Bool = false
    @State private var navigationPath = NavigationPath()
    @Namespace private var navigationTransitionNamespace

    private let tabs = ["Все", "Серии", "Копии", "Скриншоты"]

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .top) {
                ScrollView {
                    LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                        Section {
                            switch selectedTab {
                            case 0:
                                AllPhotosView(navigationPath: $navigationPath, namespace: navigationTransitionNamespace)
                            case 1:
                                SimilarPhotosView(navigationPath: $navigationPath, namespace: navigationTransitionNamespace)
                            case 2:
                                DuplicatesView(navigationPath: $navigationPath, namespace: navigationTransitionNamespace)
                            case 3:
                                ScreenshotsView(navigationPath: $navigationPath, namespace: navigationTransitionNamespace)
                            default:
                                SimilarPhotosView(navigationPath: $navigationPath, namespace: navigationTransitionNamespace)
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
                    Button(action: {
                        showSettings.toggle()
                    }) {
                        Image(systemName: "gearshape")
                    }
                    .popover(isPresented: $showSettings) {
                        SettingsTabView(isPresented: $showSettings)
                    }
                }
            }
            .refreshable {
                photoLibrary?.reset()

                await photoLibrary?.loadPhotos()
            }
            .navigationDestination(for: PhotoGroupNavigationItem.self) { item in
                PhotoDetailView(photos: item.photos, currentPhotoId: item.currentPhotoId, namespace: navigationTransitionNamespace)
            }
        }
    }
}

struct SimilarPhotosView: View {
    @Environment(\.photoLibrary) var photoLibrary
    @Binding var navigationPath: NavigationPath
    var namespace: Namespace.ID

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
                        PhotoGroupRowView(group: group, navigationPath: $navigationPath, namespace: namespace)
                    }
                }
                .padding(.top)
            }
        }
    }
}

struct DuplicatesView: View {
    @Environment(\.photoLibrary) var photoLibrary
    @Binding var navigationPath: NavigationPath
    var namespace: Namespace.ID

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
                        PhotoGroupRowView(group: group, navigationPath: $navigationPath, namespace: namespace)
                    }
                }
                .padding(.top)
            }
        }
    }
}

struct ScreenshotsView: View {
    @Environment(\.photoLibrary) var photoLibrary
    @Binding var navigationPath: NavigationPath
    var namespace: Namespace.ID

    var body: some View {
        if photoLibrary?.screenshots.isEmpty ?? true {
            EmptyStateView(
                icon: "camera.viewfinder",
                title: "Скриншоты не найдены",
                message: "В вашей галерее нет скриншотов"
            )
        } else {
            PhotoGridView(photos: photoLibrary?.screenshots ?? [], navigationPath: $navigationPath, namespace: namespace)
        }
    }
}

struct AllPhotosView: View {
    @Environment(\.photoLibrary) var photoLibrary
    @Binding var navigationPath: NavigationPath
    var namespace: Namespace.ID

    var body: some View {
        if photoLibrary?.photos.isEmpty ?? true {
            EmptyStateView(
                icon: "photo.slash",
                title: "Фотографии не найдены",
                message: "В вашей галерее нет фотографий"
            )
        } else {
            PhotoGridView(photos: photoLibrary?.photos ?? [], navigationPath: $navigationPath, namespace: namespace)
        }
    }
}

struct PhotoGroupRowView: View {
    let group: PhotoGroupModel
    @Binding var navigationPath: NavigationPath
    var namespace: Namespace.ID

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Группа (\(group.photos.count) фото)")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 1) {
                    ForEach(group.photos, id: \.id) { photo in
                        PhotoView(photo: photo, quality: .medium, contentMode: .fill)
                            .frame(width: 150, height: 200)
                            .onTapGesture {
                                navigationPath.append(PhotoGroupNavigationItem(photos: group.photos, currentPhotoId: photo.id))
                            }
                            .id(photo.id)
                            .matchedTransitionSource(id: photo.id, in: namespace)
                            .clipped()
                    }
                }
            }
            .scrollClipDisabled(true)
        }
    }
}

struct PhotoGridView: View {
    let photos: [PhotoModel]

    @Environment(\.photoLibrary) var photoLibrary
    @Binding var navigationPath: NavigationPath

    var namespace: Namespace.ID

    let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            StatisticCardView(statistics: [
                    .init(label: "Всего скриншотов", value: "\(photoLibrary?.screenshots.count ?? 0)", alignment: .leading),
                    .init(label: "Общий размер", value: FileSize(bytes: photoLibrary?.screenshotsFileSize ?? 0).formatted, alignment: .trailing),
                ])
                .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 1) {
                ForEach(photos, id: \.id) { photo in
                    PhotoView(photo: photo, quality: .medium, contentMode: .fill)
                        .frame(width: UIScreen.main.bounds.width / 3 - 1, height: UIScreen.main.bounds.width / 2)
                        .clipped()
                        .onTapGesture {
                            navigationPath.append(PhotoGroupNavigationItem(photos: photos, currentPhotoId: photo.id))
                        }
                        .id(photo.id)
                        .matchedTransitionSource(id: photo.id, in: namespace)
                }
            }
        }
    }
}
