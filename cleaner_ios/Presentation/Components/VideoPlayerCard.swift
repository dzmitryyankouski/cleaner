import SwiftUI
import AVKit

struct VideoPlayerCard: View {
    let video: VideoModel
    let isSelected: Bool
    
    @State private var player: AVPlayer?
    @State private var aspectRatio: CGFloat?
    @State private var loopObserver: NSObjectProtocol?
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if let player {
                    VideoPlayer(player: player)
                        .aspectRatio(aspectRatio, contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    Color.gray.opacity(0.3)
                }
            }
        }
        .ignoresSafeArea()
        .task {
            guard let loadedPlayer = await video.loadVideo() else { return }
            player = loadedPlayer
            aspectRatio = getAspectRatio(from: loadedPlayer)
            setupLoop(for: loadedPlayer)
            video.play()
        }
        .onDisappear {
            removeLoop()
            video.stop()
        }
    }
    
    private func getAspectRatio(from player: AVPlayer) -> CGFloat? {
        guard let track = player.currentItem?.asset.tracks(withMediaType: .video).first else {
            return nil
        }
        let size = track.naturalSize.applying(track.preferredTransform)
        return abs(size.width) / abs(size.height)
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
