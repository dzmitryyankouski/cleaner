import Foundation
import Photos
import UIKit
import AVFoundation

struct Video {
    let asset: PHAsset
    let duration: TimeInterval
    let fileSize: Int64
    let creationDate: Date?
    let modificationDate: Date?
}

class VideoService: ObservableObject {
    static let shared = VideoService()
    
    // MARK: - Properties
    @Published var videos: [Video] = []
    @Published var isLoading: Bool = false
    @Published var totalCount: Int = 0
    
    // MARK: - Initialization
    init() {
        Task {
            await loadVideosFromLibrary()
        }
    }
    
    // MARK: - Private Methods
    private func loadVideosFromLibrary() async {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        // Запрашиваем разрешение на доступ к фототеке
        let status = PHPhotoLibrary.authorizationStatus()
        
        if status == .denied || status == .restricted {
            print("❌ Доступ к фототеке запрещен")
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return
        }
        
        // Если разрешение не предоставлено, запрашиваем его
        if status == .notDetermined {
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            if newStatus == .denied || newStatus == .restricted {
                print("❌ Пользователь отказал в доступе к фототеке")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
        }
        
        let allVideos = await fetchVideosFromLibrary()
        
        DispatchQueue.main.async {
            self.videos = allVideos
            self.totalCount = allVideos.count
            self.isLoading = false
            print("✅ Загружено \(allVideos.count) видеофайлов")
        }
    }
    
    private func fetchVideosFromLibrary() async -> [Video] {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        // Получаем только видеофайлы
        let videos = PHAsset.fetchAssets(with: .video, options: fetchOptions)
        
        var videoAssets: [Video] = []
        
        // Конвертируем в массив для работы с async/await
        var assets: [PHAsset] = []
        videos.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
        // Обрабатываем каждый ассет асинхронно
        for asset in assets {
            let fileSize = await getFileSize(for: asset)
            let video = Video(
                asset: asset,
                duration: asset.duration,
                fileSize: fileSize,
                creationDate: asset.creationDate,
                modificationDate: asset.modificationDate
            )
            videoAssets.append(video)
        }
        
        return videoAssets
    }
    
    private func getFileSize(for asset: PHAsset) async -> Int64 {
        return await withCheckedContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = false
            
            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                if let urlAsset = avAsset as? AVURLAsset {
                    do {
                        let resourceValues = try urlAsset.url.resourceValues(forKeys: [.fileSizeKey])
                        let fileSize = Int64(resourceValues.fileSize ?? 0)
                        continuation.resume(returning: fileSize)
                    } catch {
                        print("❌ Ошибка получения размера файла: \(error)")
                        continuation.resume(returning: 0)
                    }
                } else {
                    continuation.resume(returning: 0)
                }
            }
        }
    }
    
    // MARK: - Public Methods
    func refreshVideos() async {
        await loadVideosFromLibrary()
    }
    
    func getVideosCount() -> Int {
        return videos.count
    }
    
    func getTotalFileSize() -> Int64 {
        return videos.reduce(0) { $0 + $1.fileSize }
    }
    
    func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
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
