import SwiftUI
import AVKit
import Photos

struct VideoPlayerView: View {
    let video: VideoModel
    
    @State private var player: AVPlayer?
    @State private var isLoading = false
    @State private var videoSize: CGSize?
    
    var body: some View {
        Group {
           if let player = player {
                VideoPlayer(player: player)
                    .aspectRatio(videoSize != nil ? videoSize!.width / videoSize!.height : nil, contentMode: .fit)
                    .ignoresSafeArea()
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
           } else {
                Color.gray.opacity(0.3)
            }
        }
        .onAppear {
            Task(priority: .userInitiated) {
                await loadPlayer()
            }
        }
    }

    private func loadPlayer() async {
        guard !isLoading && player == nil else { return }
        
        isLoading = true
        print("🔍 Загрузка видео")

        // loadAsset уже выполняется в фоновом потоке
        guard let asset = await loadAsset() else {
            await MainActor.run {
                isLoading = false
            }
            return
        }

        print("🔍 Получен asset: \(asset.localIdentifier)")

        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = false
        options.deliveryMode = .highQualityFormat
        
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

            self.player = newPlayer
            self.isLoading = false
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
