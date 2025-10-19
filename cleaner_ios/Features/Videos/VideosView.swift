import SwiftUI
import Photos
import AVKit
import AVFoundation

struct VideosView: View {
    @ObservedObject var videoService: VideoService
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Табы
                if !videoService.isLoading && !videoService.indexing && !videoService.videos.isEmpty {
                    Picker("", selection: $selectedTab) {
                        Text("Все видео").tag(0)
                        Text("Похожие видео (\(videoService.getGroupCount()))").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                // Контент в зависимости от выбранной вкладки
                if selectedTab == 0 {
                    allVideosView
                } else {
                    similarVideosView
                }
            }
            .navigationTitle("Видеофайлы")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await videoService.refreshVideos()
            }
        }
    }
    
    // MARK: - Все видео
    private var allVideosView: some View {
        VStack {
                if videoService.isLoading {
                    VStack(spacing: 20) {
                        Text("Загрузка видеофайлов")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ProgressView()
                            .scaleEffect(1.2)
                        
                        Text("Поиск видео в галерее...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                } else if videoService.indexing {
                    VStack(spacing: 20) {
                        Text("Индексация видео")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ProgressView(value: Double(videoService.indexed), total: Double(videoService.totalCount))
                            .progressViewStyle(.linear)
                            .padding(.horizontal)
                        
                        Text("\(videoService.indexed) из \(videoService.totalCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Генерация эмбеддингов для поиска...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                } else if videoService.videos.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "video.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("Видеофайлы не найдены")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("В вашей галерее нет видеофайлов")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    // Статистика
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Всего видео")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(videoService.totalCount)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Общий размер")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(videoService.formatFileSize(videoService.getTotalFileSize()))
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Список видео
                    List(videoService.videos, id: \.asset.localIdentifier) { video in
                        NavigationLink(destination: VideoPlayerView(video: video)) {
                            VideoRowView(video: video)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
    }
    
    // MARK: - Похожие видео
    private var similarVideosView: some View {
        VStack {
            if videoService.isLoading {
                VStack(spacing: 20) {
                    Text("Загрузка видеофайлов")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text("Поиск видео в галерее...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            } else if videoService.indexing {
                VStack(spacing: 20) {
                    Text("Индексация видео")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ProgressView(value: Double(videoService.indexed), total: Double(videoService.totalCount))
                        .progressViewStyle(.linear)
                        .padding(.horizontal)
                    
                    Text("\(videoService.indexed) из \(videoService.totalCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Генерация эмбеддингов для поиска...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            } else if videoService.groupsSimilar.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "video.badge.checkmark")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    Text("Похожих видео не найдено")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Отличная работа! В вашей галерее нет похожих видео")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            } else {
                // Статистика по группам
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Групп похожих")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(videoService.getGroupCount())")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Всего видео в группах")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(videoService.groupsSimilar.flatMap { $0 }.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Список групп
                List {
                    ForEach(Array(videoService.groupsSimilar.enumerated()), id: \.offset) { groupIndex, group in
                        Section(header: Text("Группа \(groupIndex + 1) • \(group.count) видео")) {
                            ForEach(group, id: \.asset.localIdentifier) { video in
                                NavigationLink(destination: VideoPlayerView(video: video)) {
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
}

struct VideoRowView: View {
    let video: Video
    
    var body: some View {
        HStack(spacing: 12) {
            // Миниатюра видео
            AsyncVideoThumbnail(asset: video.asset)
                .frame(width: 80, height: 60)
                .cornerRadius(8)
                .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                // Длительность видео
                Text(VideoService.shared.formatDuration(video.duration))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Размер файла
                Text(VideoService.shared.formatFileSize(video.fileSize))
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

struct AsyncVideoThumbnail: View {
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
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    
                    Text("Загрузка видео...")
                        .foregroundColor(.white)
                        .font(.subheadline)
                }
            } else if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                    
                    Text("Не удалось загрузить видео")
                        .foregroundColor(.white)
                        .font(.headline)
                }
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
                        // Автоматически начинаем воспроизведение
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

#Preview {
    VideosView(videoService: VideoService.shared)
}
