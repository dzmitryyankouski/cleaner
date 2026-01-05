import SwiftUI
import SwiftData
import Photos
import AVKit
import AVFoundation

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
    @Namespace private var navigationTransitionNamespace

    private let tabs = ["Все", "Похожие"]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView {
                    LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                        Section {
                            switch selectedTab {
                            case 0:
                                AllVideosView(namespace: navigationTransitionNamespace)
                            case 1:
                                SimilarVideosView(namespace: navigationTransitionNamespace)
                            default:
                                AllVideosView(namespace: navigationTransitionNamespace)
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

                VideoGrid(videos: videoLibrary?.videos ?? [], namespace: namespace)
            }
        }
    }
}

struct SimilarVideosView: View {
    @Environment(\.videoLibrary) var videoLibrary
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
                        VideoGroupRowView(group: group, namespace: namespace)
                    }
                }
                .padding(.top)
            }
        }
    }
}

struct VideoGroupRowView: View {
    let group: VideoGroupModel
    var namespace: Namespace.ID

    @State private var selectedVideo: VideoModel? = nil

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
                                selectedVideo = video
                            }
                    }
                }
            }
            .scrollClipDisabled(true)
        }
        .fullScreenCover(item: $selectedVideo) { video in
            VideoDetailView(videos: group.videos, currentItem: video, namespace: namespace)
        }
    }
}
