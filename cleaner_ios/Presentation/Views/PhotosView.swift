import SwiftUI
import SwiftData

enum FilterPhoto: String, CaseIterable {
    case screenshots = "Screenshots"
    case livePhotos = "Live Photos"
    case modified = "Modified"
    case favorites = "Favorites"
    
    var icon: String {
        switch self {
            case .screenshots: return "camera.viewfinder"
            case .livePhotos: return "livephoto"
            case .modified: return "pencil.and.scribble"
            case .favorites: return "star"
        }
    }
}

enum SortPhoto: String, CaseIterable {
    case date = "Date"
    case size = "Size"
    
    var icon: String {
        switch self {
            case .date: return "clock"
            case .size: return "arrow.up.arrow.down"
        }
    }
}

struct PhotosView: View {
    @Namespace private var navigationTransitionNamespace

    @Environment(\.photoLibrary) var photoLibrary

    @State private var selectedTab = 0
    @State private var showSettings: Bool = false
    @State private var navigationPath = NavigationPath()

    private let tabs = ["Все", "Серии", "Копии"]

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .top) {
                ScrollView {
                    LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                        Section {
                            switch selectedTab {
                            case 0:
                                AllPhotosView(namespace: navigationTransitionNamespace)
                            case 1:
                                SimilarPhotosView(namespace: navigationTransitionNamespace)
                            case 2:
                                DuplicatesView(namespace: navigationTransitionNamespace)
                            default:
                                SimilarPhotosView(namespace: navigationTransitionNamespace)
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

                if !(photoLibrary?.selectedPhotos.isEmpty ?? true) {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", systemImage: "xmark") {
                            withAnimation {
                                photoLibrary?.selectedPhotos.removeAll()
                            }
                        }
                    }
                }

                if photoLibrary?.selectedPhotos.isEmpty ?? true {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Section {
                                ForEach(FilterPhoto.allCases, id: \.self) { filter in
                                    Toggle(isOn: Binding(get: { photoLibrary?.selectedFilter.contains(filter) ?? false }, set: { value in
                                        if value {
                                            photoLibrary?.selectedFilter.insert(filter)
                                        } else {
                                            photoLibrary?.selectedFilter.remove(filter)
                                        }
                                    })) {
                                        Label(filter.rawValue, systemImage: filter.icon)
                                    }
                                }
                            }
                            Section {
                                Picker("Sort", selection: Binding(get: { photoLibrary?.selectedSort ?? .date }, set: { value in
                                    photoLibrary?.selectedSort = value
                                })) {
                                    ForEach(SortPhoto.allCases, id: \.self) { sort in
                                        Label(sort.rawValue, systemImage: sort.icon)
                                            .tag(sort)
                                    }
                                }
                            }
                        } label: {
                            Label("Фильтры", systemImage: "line.3.horizontal.decrease")
                        }
                    }
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            showSettings.toggle()
                        }) {
                            Image(systemName: "gearshape")
                        }
                        .popover(isPresented: $showSettings) {
                            SettingsView(isPresented: $showSettings)
                        }
                    }
                } else {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button(role: .destructive, action: {
                                Task {
                                    guard let result = await photoLibrary?.delete(photos: photoLibrary?.selectedPhotos ?? []) else {
                                        return
                                    }

                                    guard case .success = result else {
                                        return
                                    }

                                    await photoLibrary?.refresh()

                                    withAnimation {
                                        photoLibrary?.selectedPhotos.removeAll()
                                    }
                                }
                            }) {
                                Label("Remove", systemImage: "trash")
                            }

                            Button(action: {
                                Task {
                                    print("🔍 Удаляем живое фото: \(photoLibrary?.selectedPhotos.count ?? 0)")
                                    guard let result = await photoLibrary?.removeLive(photos: photoLibrary?.selectedPhotos ?? []) else {
                                        print("❌ Не удалось удалить живое фото")
                                        return
                                    }

                                    guard case .success = result else {
                                        print("❌ Не удалось удалить живое фото")
                                        return
                                    }

                                    withAnimation {
                                        photoLibrary?.selectedPhotos.removeAll()
                                    }
                                }
                            }) {
                                Label("Remove Live", systemImage: "livephoto")
                            }

                            Button(action: {
                                Task {
                                    guard let result = await photoLibrary?.compress(photos: photoLibrary?.selectedPhotos ?? []) else {
                                        return
                                    }

                                    guard case .success = result else {
                                        return
                                    }

                                    withAnimation {
                                        photoLibrary?.selectedPhotos.removeAll()
                                    }
                                }
                            }) {
                                Label("Compress", systemImage: "arrow.down.to.line")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                    }
                }
            }
            .refreshable {
                Task {
                    await photoLibrary?.reset()
                }
            }
        }
    }
}

struct SimilarPhotosView: View {
    @Environment(\.photoLibrary) var photoLibrary

    var namespace: Namespace.ID

    var body: some View {
        if photoLibrary?.indexing ?? false {
            ProgressLoadingCard(
                title: "Индексация фотографий",
                current: photoLibrary?.indexed ?? 0,
                total: photoLibrary?.total ?? 0
            )
            .padding(.horizontal)
        } else if photoLibrary?.similarGroups.isEmpty ?? true {
            EmptyState(
                icon: "photo.on.rectangle.angled",
                title: "Похожие фотографии не найдены",
                message: "Попробуйте выбрать другие изображения"
            )
        } else {
            LazyVStack(alignment: .leading, spacing: 16) {
                StatisticCard {
                    StatisticItem(label: "Найдено групп", value: "\(photoLibrary?.similarGroups.count ?? 0)", alignment: .leading)
                    StatisticItem(label: "Фото в группах", value: "\(photoLibrary?.similarPhotosCount ?? 0)", alignment: .center)
                    StatisticItem(label: "Общий размер", value: FileSize(bytes: photoLibrary?.similarPhotosFileSize ?? 0).formatted, alignment: .trailing)
                }
                .padding(.horizontal)

                LazyVStack(spacing: 20) {
                    ForEach(photoLibrary?.similarGroups ?? [], id: \.id) { group in
                        PhotoGridPreview(photos: group.photos, namespace: namespace)
                    }
                }
                .padding()
            }
        }
    }
}

struct DuplicatesView: View {
    @Environment(\.photoLibrary) var photoLibrary
    var namespace: Namespace.ID

    var body: some View {
        if photoLibrary?.indexing ?? false {
            ProgressLoadingCard(
                title: "Индексация фотографий",
                current: photoLibrary?.indexed ?? 0,
                total: photoLibrary?.total ?? 0
            )
            .padding(.horizontal)
        } else if photoLibrary?.duplicatesGroups.isEmpty ?? true {
            EmptyState(
                icon: "doc.on.doc",
                title: "Дубликаты не найдены",
                message: "В вашей галерее нет точных копий фотографий"
            )
        } else {
            LazyVStack(alignment: .leading, spacing: 16) {
                StatisticCard {
                    StatisticItem(label: "Найдено групп", value: "\(photoLibrary?.duplicatesGroups.count ?? 0)", alignment: .leading)
                    StatisticItem(label: "Фото в группах", value: "\(photoLibrary?.duplicatesPhotosCount ?? 0)", alignment: .center)
                    StatisticItem(label: "Общий размер", value: FileSize(bytes: photoLibrary?.duplicatesPhotosFileSize ?? 0).formatted, alignment: .trailing)
                }
                .padding(.horizontal)

                LazyVStack(spacing: 20) {
                    ForEach(photoLibrary?.duplicatesGroups ?? [], id: \.id) { group in
                        PhotoGroupRowView(group: group, namespace: namespace)
                    }
                }
                .padding(.top)
            }
        }
    }
}

struct AllPhotosView: View {
    @Environment(\.photoLibrary) var photoLibrary
    var namespace: Namespace.ID

    var body: some View {
        if photoLibrary?.photos.isEmpty ?? true && !(photoLibrary?.indexing ?? false) {
            EmptyState(
                icon: "photo",
                title: "Фотографии не найдены",
                message: "В вашей галерее нет фотографий"
            )
        } else {
            VStack(spacing: 12) {
                if photoLibrary?.indexing ?? false {
                    ProgressLoadingCard(
                        title: "Индексация фотографий",
                        current: photoLibrary?.indexed ?? 0,
                        total: photoLibrary?.total ?? 0
                    )
                    .padding(.horizontal)
                } else {
                    StatisticCard {
                        StatisticItem(label: "Всего фотографий", value: "\(photoLibrary?.photos.count ?? 0)", alignment: .leading)
                        StatisticItem(label: "Общий размер", value: FileSize(bytes: photoLibrary?.photosFileSize ?? 0).formatted, alignment: .trailing)
                    }
                    .padding(.horizontal)
                }

                PhotoGridPreview(photos: photoLibrary?.photos ?? [], namespace: namespace)
                    .padding(.horizontal)
            }
        }
    }
}

struct PhotoGroupRowView: View {
    @Environment(\.photoLibrary) var photoLibrary

    let group: PhotoGroupModel
    var namespace: Namespace.ID

    @State private var selectedPhoto: PhotoModel? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Группа (\(group.photos.count) фото)")
                .font(.headline)
                .padding(.horizontal)

            RowItems(items: group.photos, selectedItems: photoLibrary?.selectedPhotos ?? [], namespace: namespace) { photo in
                Photo(photo: photo, quality: .medium, contentMode: .fill)
            } onSelect: { photo in
                photoLibrary?.select(photo: photo)
            } onTap: { photo in
                selectedPhoto = photo
            }
        }
        .fullScreenCover(item: $selectedPhoto) { photo in
            PhotoDetailView(photos: group.photos, currentItem: photo, namespace: namespace)
        }
    }
}
