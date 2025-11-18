import SwiftUI
import SwiftData
import Photos
import AVKit

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

struct VideosTabView: View {
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
                            SimilarVideosView(navigationPath: $navigationPath, namespace: navigationTransitionNamespace)
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
                videoLibrary?.reset()
                await videoLibrary?.loadVideos()
            }
            .navigationDestination(for: VideoGroupNavigationItem.self) { item in
                VideoDetailView(videos: item.videos, currentVideoId: item.currentVideoId, namespace: navigationTransitionNamespace)
            }
        }
    }
}

struct AllVideosView: View {
    @Environment(\.videoLibrary) var videoLibrary
    @Binding var navigationPath: NavigationPath
    var namespace: Namespace.ID

    var body: some View {
        // if videoLibrary?.indexing ?? false {
        //     ProgressLoadingView(
        //         title: "Индексация видео",
        //         current: videoLibrary?.indexed ?? 0,
        //         total: videoLibrary?.total ?? 0
        //     )
        //     .padding(.horizontal)
        // } else {

        //     if allVideos.isEmpty {
        //         EmptyStateView(
        //             icon: "video.slash",
        //             title: "Видео не найдены",
        //             message: "В вашей галерее нет видео"
        //         )
        //     } else {
        //         LazyVStack(spacing: 20) {
        //             ForEach(allVideos, id: \.id) { video in
        //                 VideoThumbnailCard(video: video, navigationPath: $navigationPath, namespace: namespace)
        //             }
        //         }
        //         .padding(.horizontal)
        //     }
        // }
    }
}

struct SimilarVideosView: View {
    @Environment(\.videoLibrary) var videoLibrary
    @Binding var navigationPath: NavigationPath
    var namespace: Namespace.ID

    var body: some View {
        if videoLibrary?.indexing ?? false {
            ProgressLoadingView(
                title: "Индексация видео",
                current: videoLibrary?.indexed ?? 0,
                total: videoLibrary?.total ?? 0
            )
            .padding(.horizontal)
        } else if videoLibrary?.similarGroups.isEmpty ?? true {
            EmptyStateView(
                icon: "video.badge.checkmark",
                title: "Похожие видео не найдены",
                message: "Попробуйте выбрать другие видео"
            )
        } else {
            LazyVStack(alignment: .leading, spacing: 16) {
                StatisticCardView(statistics: [
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
                LazyHStack(spacing: 12) {
                    ForEach(group.videos, id: \.id) { video in
                        VideoView(video: video, quality: .medium, contentMode: .fill)
                            .frame(width: 150, height: 200)
                            .cornerRadius(8)
                            .clipped()
                            .onTapGesture {
                                navigationPath.append(VideoGroupNavigationItem(videos: group.videos, currentVideoId: video.id))
                            }
                            .id(video.id)
                            .matchedTransitionSource(id: video.id, in: namespace)
                    }
                }
                .padding(.horizontal)
            }
            .scrollClipDisabled(true)
        }
    }
}

struct VideoThumbnailCard: View {
    let video: VideoModel
    @Binding var navigationPath: NavigationPath
    var namespace: Namespace.ID
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VideoView(video: video, quality: .medium, contentMode: .fill)
                .frame(height: 200)
                .cornerRadius(8)
                .clipped()
            
            HStack {
                if let creationDate = video.creationDate {
                    Text(formatDate(creationDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(formatDuration(video.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onTapGesture {
            // Для одиночного видео создаем группу из одного элемента
            navigationPath.append(VideoGroupNavigationItem(videos: [video], currentVideoId: video.id))
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

enum VideoQuality {
    case low
    case medium
    case high
}

struct VideoView: View {
    let video: VideoModel
    let quality: VideoQuality
    let contentMode: ContentMode

    @State private var thumbnail: UIImage?
    @State private var isLoading = false
    
    private let manager = PHCachingImageManager()
    
    init(video: VideoModel, quality: VideoQuality, contentMode: ContentMode) {
        self.video = video
        self.quality = quality
        self.contentMode = contentMode
    }

    var body: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                Color.gray.opacity(contentMode == .fill ? 0.3 : 0)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                    )
                    .onAppear {
                        loadThumbnail()
                    }
            }
        }
    }
    
    private func loadThumbnail() {
        guard !isLoading && thumbnail == nil else { return }
        isLoading = true

        Task {
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [video.id], options: nil)
            guard let asset = assets.firstObject else {
                await MainActor.run {
                    isLoading = false
                }
                return
            }
            
            await loadThumbnailFromAsset(asset)
        }
    }
    
    private func loadThumbnailFromAsset(_ asset: PHAsset) async {
        let options = PHImageRequestOptions()
        
        options.isSynchronous = false
        options.isNetworkAccessAllowed = false
        options.deliveryMode = .opportunistic
        
        switch quality {
        case .low:
            options.resizeMode = .fast
        case .medium:
            options.resizeMode = .exact
        case .high:
            options.resizeMode = .none
            options.deliveryMode = .highQualityFormat
        }

        let targetSize = getTargetSize()
        
        manager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            DispatchQueue.main.async {
                self.thumbnail = image
                self.isLoading = false
            }
        }
    }

    private func getTargetSize() -> CGSize {
        switch quality {
        case .low:
            return CGSize(width: 150, height: 200)
        case .medium:
            return CGSize(width: 300, height: 400)
        case .high:
            return PHImageManagerMaximumSize
        }
    }
}
