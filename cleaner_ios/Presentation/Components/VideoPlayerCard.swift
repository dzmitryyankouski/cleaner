import SwiftUI
import AVKit

struct VideoPlayerCard: View {
    let video: VideoModel
    let isSelected: Bool
    
    @State private var player: AVPlayer?
    @State private var loopObserver: NSObjectProtocol?
    
    var body: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
                    .aspectRatio(contentMode: .fit)
                    .ignoresSafeArea()
            } else {
                Color.gray.opacity(0.3)
            }
        }
        .task {
            guard let loadedPlayer = await video.loadVideo() else { return }
            player = loadedPlayer
            setupLoop(for: loadedPlayer)
            video.play()
        }
        .onDisappear {
            removeLoop()
            video.stop()
        }
    }
    
    private func setupLoop(for player: AVPlayer) {
        removeLoop()
        guard let playerItem = player.currentItem else { return }
        
        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
    }
    
    private func removeLoop() {
        if let observer = loopObserver {
            NotificationCenter.default.removeObserver(observer)
            loopObserver = nil
        }
    }
}
