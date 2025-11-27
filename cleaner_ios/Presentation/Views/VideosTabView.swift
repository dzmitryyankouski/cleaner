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
                LazyHStack(spacing: 1) {
                    ForEach(group.videos, id: \.id) { video in
                        VideoThumbnailView(video: video)
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

struct VideoThumbnailView: View {
    let video: VideoModel

    @State private var thumbnail: UIImage?
    @State private var isLoading = false
    
    init(video: VideoModel) {
        self.video = video
    }

    var body: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.gray.opacity(0.3)
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
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = false
        
        await withCheckedContinuation { continuation in
            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                guard let avAsset = avAsset else {
                    Task { @MainActor in
                        self.isLoading = false
                    }
                    continuation.resume()
                    return
                }
                
                Task {
                    await self.generateThumbnail(from: avAsset)
                    continuation.resume()
                }
            }
        }
    }
    
    private func generateThumbnail(from avAsset: AVAsset) async {
        let imageGenerator = AVAssetImageGenerator(asset: avAsset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceAfter = .zero
        imageGenerator.requestedTimeToleranceBefore = .zero
        
        let targetSize = CGSize(width: 300, height: 400)
        imageGenerator.maximumSize = targetSize
        
        do {
            let time = CMTime(seconds: 0.0, preferredTimescale: 600)
            let cgImage = try await imageGenerator.image(at: time).image
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.thumbnail = UIImage(cgImage: cgImage)
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.isLoading = false
                }
            }
        }
    }
}