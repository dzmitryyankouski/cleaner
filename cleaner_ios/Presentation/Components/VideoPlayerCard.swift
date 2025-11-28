import SwiftUI
import AVKit
import AVFoundation
import Photos

struct VideoPlayerCard: View {
    let video: VideoModel
    let isSelected: Bool
    
    @State private var player: AVPlayer?
    @State private var isLoading = false
    @State private var videoSize: CGSize?
    @State private var playerItemObserver: NSObjectProtocol?
    
    var body: some View {
        Group {
           if let player = player {
                VideoPlayer(player: player)
                    .aspectRatio(videoSize != nil ? videoSize!.width / videoSize!.height : nil, contentMode: .fit)
                    .ignoresSafeArea()
           } else {
                Color.gray.opacity(0.3)
            }
        }
        .onAppear {
            Task(priority: .userInitiated) {
                await loadPlayer()
            }
        }
        .onDisappear {
            print("🔍 Удаление observer")
            if let observer = playerItemObserver {
                NotificationCenter.default.removeObserver(observer)
                playerItemObserver = nil
            }
        }
        .onChange(of: isSelected) { oldValue, newValue in
            guard let player = player else { return }
            if newValue {
                player.play()
            } else {
                player.pause()
                player.seek(to: .zero)
            }
        }
    }

    private func loadPlayer() async {
        guard !isLoading && player == nil else { 
            self.playerItemObserver = self.setupPlayerLoop(for: player)
            return
         }
        
        isLoading = true
        print("🔍 Загрузка видео")

        guard let asset = await loadAsset() else {
            await MainActor.run {
                isLoading = false
            }
            return
        }

        print("🔍 Получен asset: \(asset.localIdentifier)")

        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = false
        options.deliveryMode = .automatic
        
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
            print("🔍 Получен AVAsset: \(avAsset)")

            guard let urlAsset = avAsset as? AVURLAsset else {
                print("❌ Не удалось получить AVURLAsset")
                return
            }

            print("🔍 Получен URL: \(urlAsset.url)")

            let videoTracks = urlAsset.tracks(withMediaType: .video)
            if let videoTrack = videoTracks.first {
                let size = videoTrack.naturalSize
                let transform = videoTrack.preferredTransform
                let videoSize = transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0
                    ? CGSize(width: size.height, height: size.width)
                    : size
                
                self.videoSize = videoSize
            }

            let newPlayer = AVPlayer(url: urlAsset.url)

            Task { @MainActor in
                self.player = newPlayer
                self.isLoading = false
                
                if self.isSelected {
                    newPlayer.seek(to: .zero)
                    newPlayer.play()

                    self.playerItemObserver = self.setupPlayerLoop(for: newPlayer)
                }
            }
        }
    }

    private func setupPlayerLoop(for player: AVPlayer?) -> NSObjectProtocol? {
        print("🔍 Установка observer")
        if let observer = playerItemObserver {
            NotificationCenter.default.removeObserver(observer)
            playerItemObserver = nil
        }
        
        if let playerItem = player?.currentItem {
            let observer = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerItem,
                queue: .main
            ) { [weak player] _ in
                guard let player = player else { return }

                print("🔍 Автоповтор видео")
                player.seek(to: .zero)
                player.play()
            }
            self.playerItemObserver = observer
            return observer
        }
        
        return nil
    }

    private func removePlayerItemObserver() {
        if let observer = playerItemObserver {
            NotificationCenter.default.removeObserver(observer)
            playerItemObserver = nil
        }
    }
    
    private func loadAsset() async -> PHAsset? {
        let videoId = video.id
        return await Task.detached(priority: .userInitiated) { () -> PHAsset? in
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [videoId], options: nil)
            guard let asset = assets.firstObject else { return nil }

            return asset
        }.value
    }
}
