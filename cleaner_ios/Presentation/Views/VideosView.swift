import SwiftUI
import SwiftData
import Photos
import AVKit
import AVFoundation

struct VideoGroupNavigationItem: Hashable {
    let videos: [VideoModel]
    let currentVideoId: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(videos.map { $0.id }.joined())
        hasher.combine(currentVideoId)
    }
    
    static func == (lhs: VideoGroupNavigationItem, rhs: VideoGroupNavigationItem) -> Bool {
        lhs.videos.map { $0.id } == rhs.videos.map { $0.id } && lhs.currentVideoId == rhs.currentVideoId
    }
}

enum FilterVideo: String, CaseIterable {
    case modified = "Modified"
    case favorites = "Favorites"
    
    var icon: String {
        switch self {
            case .modified: return "pencil.and.scribble"
            case .favorites: return "star"
        }
    }
}

enum SortVideo: String, CaseIterable {
    case date = "Date"
    case size = "Size"
    
    var icon: String {
        switch self {
            case .date: return "clock"
            case .size: return "arrow.up.arrow.down"
        }
    }
}

struct VideosView: View {
    @Environment(\.videoLibrary) var videoLibrary
    @State private var selectedTab = 0
    @State private var showSettings: Bool = false
    @State private var navigationPath = NavigationPath()
    @Namespace private var navigationTransitionNamespace

    private let tabs = ["Все", "Похожие"]

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .top) {
                ScrollView {
                    LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                        Section {
                            switch selectedTab {
                            case 0:
                                AllVideosView(navigationPath: $navigationPath, namespace: navigationTransitionNamespace)
                            case 1:
                                SimilarVideosView(navigationPath: $navigationPath, namespace: navigationTransitionNamespace)
                            default:
                                AllVideosView(navigationPath: $navigationPath, namespace: navigationTransitionNamespace)
                            }
                        } header: {
                            PickerHeader(selectedTab: $selectedTab, tabs: tabs)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Видео")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section {
                            ForEach(FilterVideo.allCases, id: \.self) { filter in
                                Toggle(isOn: Binding(get: { videoLibrary?.selectedFilter.contains(filter) ?? false }, set: { value in
                                    if value {
                                        videoLibrary?.selectedFilter.insert(filter)
                                    } else {
                                        videoLibrary?.selectedFilter.remove(filter)
                                    }
                                })) {
                                    Label(filter.rawValue, systemImage: filter.icon)
                                }
                            }
                        }
                        Section {
                            Picker("Sort", selection: Binding(get: { videoLibrary?.selectedSort ?? .date }, set: { value in
                                videoLibrary?.selectedSort = value
                            })) {
                                ForEach(SortVideo.allCases, id: \.self) { sort in
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
            }
            .refreshable {
                Task {
                    await videoLibrary?.reset()
                }
            }
            .navigationDestination(for: VideoGroupNavigationItem.self) { item in
                VideoDetailView(videos: item.videos, currentVideoId: item.currentVideoId, namespace: navigationTransitionNamespace)
            }
            .onChange(of: videoLibrary?.selectedFilter) { _, _ in
                Task {
                    await videoLibrary?.filter()
                }
            }
            .onChange(of: videoLibrary?.selectedSort) { _, _ in
                Task {
                    await videoLibrary?.filter()
                }
            }
        }
    }
}

struct AllVideosView: View {
    @Environment(\.videoLibrary) var videoLibrary
    @Binding var navigationPath: NavigationPath
    var namespace: Namespace.ID

    var body: some View {
        if videoLibrary?.videos.isEmpty ?? true && !(videoLibrary?.indexing ?? false) {
            EmptyState(
                icon: "video",
                title: "Видео не найдены",
                message: "В вашей галерее нет видео"
            )
        } else {
            VStack(spacing: 12) {
                if videoLibrary?.indexing ?? false {
                    ProgressLoadingCard(
                        title: "Индексация видео",
                        current: videoLibrary?.indexed ?? 0,
                        total: videoLibrary?.total ?? 0
                    )
                    .padding(.horizontal)
                } else {
                    StatisticCard(statistics: [
                        .init(label: "Всего видео", value: "\(videoLibrary?.videos.count ?? 0)", alignment: .leading),
                        .init(label: "Общий размер", value: FileSize(bytes: videoLibrary?.videosFileSize ?? 0).formatted, alignment: .trailing),
                    ])
                    .padding(.horizontal)
                }

                VideoGrid(videos: videoLibrary?.videos ?? [], navigationPath: $navigationPath, namespace: namespace)
            }
        }
    }
}

struct SimilarVideosView: View {
    @Environment(\.videoLibrary) var videoLibrary
    @Binding var navigationPath: NavigationPath
    var namespace: Namespace.ID

    var body: some View {
        if videoLibrary?.indexing ?? false {
            ProgressLoadingCard(
                title: "Индексация видео",
                current: videoLibrary?.indexed ?? 0,
                total: videoLibrary?.total ?? 0
            )
            .padding(.horizontal)
        } else if videoLibrary?.similarGroups.isEmpty ?? true {
            EmptyState(
                icon: "video.badge.checkmark",
                title: "Похожие видео не найдены",
                message: "Попробуйте выбрать другие видео"
            )
        } else {
            LazyVStack(alignment: .leading, spacing: 16) {
                StatisticCard(statistics: [
                    .init(label: "Найдено групп", value: "\(videoLibrary?.similarGroups.count ?? 0)", alignment: .leading),
                    .init(label: "Видео в группах", value: "\(videoLibrary?.similarVideos.count ?? 0)", alignment: .center),
                    .init(label: "Общий размер", value: FileSize(bytes: videoLibrary?.similarVideosFileSize ?? 0).formatted, alignment: .trailing),
                ])
                .padding(.horizontal)

                LazyVStack(spacing: 20) {
                    ForEach(videoLibrary?.similarGroups ?? [], id: \.id) { group in
                        VideoGroupRowView(group: group, navigationPath: $navigationPath, namespace: namespace)
                    }
                }
                .padding(.top)
            }
        }
    }
}

struct VideoGroupRowView: View {
    let group: VideoGroupModel
    @Binding var navigationPath: NavigationPath
    var namespace: Namespace.ID

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Группа (\(group.videos.count) видео)")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 1) {
                    ForEach(group.videos, id: \.id) { video in
                        VideoThumbnail(video: video)
                            .id(video.id)
                            .frame(width: 150, height: 200)
                            .clipped()
                            .matchedTransitionSource(id: video.id, in: namespace)
                            .onTapGesture {
                                navigationPath.append(VideoGroupNavigationItem(videos: group.videos, currentVideoId: video.id))
                            }
                    }
                }
            }
            .scrollClipDisabled(true)
        }
    }
}
