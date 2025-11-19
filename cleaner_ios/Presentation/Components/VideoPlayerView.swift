import SwiftUI
import AVKit
import Photos

struct VideoPlayerView: View {
    let video: VideoModel
    
    @State private var player: AVPlayer?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let player = player {
                Color.red.opacity(0.3)
                // VideoPlayer(player: player)
                //     .ignoresSafeArea()
                //     .onAppear {
                //         player.play()
                //     }
                //     .onDisappear {
                //         player.pause()
                //     }
            } else {
                Color.gray.opacity(0.3)
            }
        }
        .onAppear {
            // Откладываем загрузку, чтобы не мешать анимации перехода
            Task(priority: .userInitiated) {
                // Небольшая задержка для завершения анимации перехода
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 секунды
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
        
        // Загрузка AVAsset в фоновом потоке
        let avAsset = await Task.detached(priority: .userInitiated) {
            await withCheckedContinuation { continuation in
                PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                    continuation.resume(returning: avAsset)
                }
            }
        }.value

        guard let urlAsset = avAsset as? AVURLAsset else {
            print("❌ Не удалось получить AVURLAsset")
            await MainActor.run {
                isLoading = false
            }
            return
        }

        print("🔍 Получен URL: \(urlAsset.url)")
        
        let newPlayer = AVPlayer(url: urlAsset.url)
        self.player = newPlayer
        self.isLoading = false
        print("🔍 Получен Player: \(newPlayer)")
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
