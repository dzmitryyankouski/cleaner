import SwiftUI
import Photos

struct VideosView: View {
    @ObservedObject var videoService = VideoService.shared
    
    var body: some View {
        NavigationView {
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
                        VideoRowView(video: video)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Видеофайлы")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Обновить") {
                        Task {
                            await videoService.refreshVideos()
                        }
                    }
                    .disabled(videoService.isLoading)
                }
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

#Preview {
    VideosView()
}
