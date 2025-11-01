import SwiftUI
import Photos
import AVKit

// MARK: - Videos Tab View

struct VideosTabView: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: VideoViewModel
    @State private var selectedTab = 0
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Табы
                if !viewModel.isLoading && !viewModel.indexing && !viewModel.videos.isEmpty {
                    Picker("", selection: $selectedTab) {
                        Text("Все видео").tag(0)
                        Text("Похожие видео (\(viewModel.groupsCount))").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                if viewModel.indexing {
                    ProgressLoadingView(
                        title: "Индексация видео",
                        current: viewModel.indexed,
                        total: viewModel.total
                    )
                } else {
                    tabContent
                }
            }
            .navigationTitle("Видеофайлы")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.refreshVideos()
            }
            .navigationDestination(for: Video.self) { video in
                VideoPlayerView(video: video)
            }
        }
    }


    // MARK: - Tab Content
    
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0:
            allVideosView
        case 1:
            similarVideosView
        default:
            allVideosView
        }
    }
    
    // MARK: - All Videos View
    
    @ViewBuilder
    private var allVideosView: some View {
        if viewModel.isLoading {
            LoadingView(
                title: "Загрузка видеофайлов",
                message: "Поиск видео в галерее..."
            )
        } else if viewModel.indexing {
            ProgressLoadingView(
                title: "Индексация видео",
                current: viewModel.indexed,
                total: viewModel.total,
                message: "Генерация эмбеддингов для поиска..."
            )
        } else if viewModel.videos.isEmpty {
            EmptyStateView(
                icon: "video.slash",
                title: "Видеофайлы не найдены",
                message: "В вашей галерее нет видеофайлов"
            )
        } else {
            VStack(spacing: 8) {
                // Статистика
                StatisticCardView(statistics: [
                    .init(label: "Всего видео", value: "\(viewModel.videosCount)", alignment: .leading),
                    .init(label: "Общий размер", value: viewModel.formattedTotalFileSize, alignment: .trailing)
                ])
                .padding(.horizontal)
                
                // Список видео
                List(viewModel.videos) { video in
                    NavigationLink(value: video) {
                        VideoRowView(video: video)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    // MARK: - Similar Videos View
    
    @ViewBuilder
    private var similarVideosView: some View {
        if viewModel.isLoading {
            LoadingView(
                title: "Загрузка видеофайлов",
                message: "Поиск видео в галерее..."
            )
        } else if viewModel.indexing {
            ProgressLoadingView(
                title: "Индексация видео",
                current: viewModel.indexed,
                total: viewModel.total,
                message: "Генерация эмбеддингов для поиска..."
            )
        } else if viewModel.groupsSimilar.isEmpty {
            EmptyStateView(
                icon: "video.badge.checkmark",
                title: "Похожих видео не найдено",
                message: "Отличная работа! В вашей галерее нет похожих видео"
            )
        } else {
            VStack(spacing: 8) {
                // Статистика по группам
                StatisticCardView(statistics: [
                    .init(label: "Групп похожих", value: "\(viewModel.groupsCount)", alignment: .leading),
                    .init(label: "Всего видео", value: "\(totalVideosInGroups)", alignment: .trailing)
                ])
                .padding(.horizontal)
                
                // Список групп
                List {
                    ForEach(Array(viewModel.groupsSimilar.enumerated()), id: \.offset) { groupIndex, group in
                        Section(header: Text("Группа \(groupIndex + 1) • \(group.count) видео")) {
                            ForEach(group.items) { video in
                                NavigationLink(value: video) {
                                    VideoRowView(video: video)
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var totalVideosInGroups: Int {
        viewModel.groupsSimilar.reduce(0) { $0 + $1.count }
    }
}

// MARK: - Video Row View

struct VideoRowView: View {
    let video: Video
    
    var body: some View {
        HStack(spacing: 12) {
            // Миниатюра видео
            VideoThumbnailView(asset: video.asset)
                .frame(width: 80, height: 60)
                .cornerRadius(8)
                .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                // Длительность видео
                Text(video.duration.formatted)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Размер файла
                Text(video.fileSize.formatted)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Дата создания
                if let creationDate = video.creationDate {
                    Text(formatDate(creationDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Иконка видео
            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Video Thumbnail View

struct VideoThumbnailView: View {
    let asset: PHAsset
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                    )
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .opportunistic
        requestOptions.resizeMode = .exact
        requestOptions.isNetworkAccessAllowed = false
        
        let targetSize = CGSize(width: 160, height: 120)
        
        imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: requestOptions
        ) { image, _ in
            DispatchQueue.main.async {
                self.thumbnail = image
            }
        }
    }
}

// MARK: - Video Player View

struct VideoPlayerView: View {
    let video: Video
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoading {
                LoadingView(
                    title: "Загрузка видео..."
                )
            } else if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                EmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: "Не удалось загрузить видео",
                    message: "Попробуйте еще раз"
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text("Видео")
                        .font(.headline)
                    if let date = video.creationDate {
                        Text(formatDate(date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onAppear {
            loadVideo()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
    
    private func loadVideo() {
        Task {
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat
            
            PHImageManager.default().requestAVAsset(forVideo: video.asset, options: options) { avAsset, _, _ in
                DispatchQueue.main.async {
                    if let urlAsset = avAsset as? AVURLAsset {
                        self.player = AVPlayer(url: urlAsset.url)
                        self.isLoading = false
                        self.player?.play()
                    } else {
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

