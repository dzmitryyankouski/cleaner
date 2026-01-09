import SwiftData
import Photos
import AVFoundation
import UIKit

@Model
final class VideoModel: Identifiable {
    @Attribute(.unique) var id: String
    @Relationship(deleteRule: .nullify)
    var groups: [VideoGroupModel] = []
    
    var duration: TimeInterval
    var creationDate: Date?
    var modificationDate: Date?
    var embedding: [Float]?
    var fileSize: Int64?
    var isModified: Bool = false
    var isFavorite: Bool = false
    
    // MARK: - Transient (not saved to database)
    @Transient var previewImage: UIImage?
    @Transient var isLoadingPreview: Bool = false
    @Transient var player: AVPlayer?
    @Transient var isLoadingVideo: Bool = false
    @Transient var isPlaying: Bool = false
    
    // MARK: - Static
    private static let imageManager = PHCachingImageManager()

    init(asset: PHAsset) {
        self.id = asset.localIdentifier
        self.duration = asset.duration
        self.creationDate = asset.creationDate
        self.modificationDate = asset.modificationDate
    }
    
    // MARK: - Preview Loading
    
    @MainActor
    func loadPreview() async -> UIImage? {
        if let cached = previewImage {
            return cached
        }
        
        if isLoadingPreview {
            return previewImage
        }
        
        isLoadingPreview = true
        
        let videoId = self.id
        
        let loadedImage: UIImage? = await withCheckedContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                let assets = PHAsset.fetchAssets(withLocalIdentifiers: [videoId], options: nil)
                guard let asset = assets.firstObject else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let options = PHImageRequestOptions()
                options.isSynchronous = false
                options.isNetworkAccessAllowed = true
                options.resizeMode = .exact
                options.deliveryMode = .opportunistic
                
                let targetSize = CGSize(width: 300, height: 400)
                
                Self.imageManager.requestImage(
                    for: asset,
                    targetSize: targetSize,
                    contentMode: .aspectFill,
                    options: options
                ) { image, info in
                    let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                    if !isDegraded {
                        continuation.resume(returning: image)
                    }
                }
            }
        }
        
        previewImage = loadedImage
        isLoadingPreview = false
        
        return previewImage
    }
    
    // MARK: - Video Loading & Playback
    
    @MainActor
    func loadVideo() async -> AVPlayer? {
        if let player {
            return player
        }
        
        if isLoadingVideo {
            return player
        }
        
        isLoadingVideo = true
        
        let videoId = self.id
        
        let loadedPlayer: AVPlayer? = await withCheckedContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                let assets = PHAsset.fetchAssets(withLocalIdentifiers: [videoId], options: nil)
                guard let asset = assets.firstObject else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let options = PHVideoRequestOptions()
                options.isNetworkAccessAllowed = true
                options.deliveryMode = .automatic
                
                PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { playerItem, _ in
                    if let playerItem {
                        let player = AVPlayer(playerItem: playerItem)
                        player.isMuted = false
                        
                        do {
                            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                            try AVAudioSession.sharedInstance().setActive(true)
                        } catch {
                            print("❌ Ошибка настройки AVAudioSession: \(error)")
                        }
                        
                        continuation.resume(returning: player)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
        
        player = loadedPlayer
        isLoadingVideo = false
        
        return player
    }
    
    @MainActor
    func play() {
        guard let player else { return }
        
        player.play()
        isPlaying = true
    }
    
    @MainActor
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    @MainActor
    func stop() {
        player?.pause()
        player?.seek(to: .zero)
        isPlaying = false
    }

    static var similar: FetchDescriptor<VideoModel> {
        FetchDescriptor(
            predicate: #Predicate<VideoModel> { video in
                video.groups.contains { $0.type == "similar" }
            }
        )
    }

    static var withEmbedding: FetchDescriptor<VideoModel> {
        FetchDescriptor(
            predicate: #Predicate<VideoModel> { $0.embedding != nil }
        )
    }

    static func apply(filter: Set<FilterVideo>, sort: SortVideo, type: String? = nil) -> FetchDescriptor<VideoModel> {
        let sortDescriptors: [SortDescriptor<VideoModel>]
        switch sort {
            case .date:
                sortDescriptors = [SortDescriptor(\.creationDate, order: .reverse)]
            case .size:
                sortDescriptors = [SortDescriptor(\.fileSize, order: .reverse)]
        }

        var filterPredicate = #Predicate<VideoModel> { _ in true }
        var groupPredicate = #Predicate<VideoModel> { _ in true }

        if !filter.isEmpty {
            let hasModified = filter.contains(.modified)
            let hasFavorites = filter.contains(.favorites)

            filterPredicate = #Predicate<VideoModel> { video in
                (hasModified && video.isModified) ||
                (hasFavorites && video.isFavorite)
            }
        }

        if let type = type {
            groupPredicate = #Predicate<VideoModel> { video in
                video.groups.contains { $0.type == type }
            }
        }

        let predicate = #Predicate<VideoModel> { video in
            filterPredicate.evaluate(video) && groupPredicate.evaluate(video)
        }
        
        return FetchDescriptor(
            predicate: predicate,
            sortBy: sortDescriptors
        )
    }
}
