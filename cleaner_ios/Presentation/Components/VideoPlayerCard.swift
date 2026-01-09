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
                    PlayerView(player: player)
                        .aspectRatio(aspectRatio, contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    VideoThumbnail(video: video)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.height)
               }
            }
        }
        .ignoresSafeArea()
        .task {
            await loadVideo()

            if isSelected {
                video.play()
            }
        }
        .onChange(of: isSelected) { _, newValue in
            if newValue {
                Task {
                    await loadVideo()
                    video.play()
                }
            } else {
                removeLoop()
                video.stop()
            }
        }
        .onDisappear {
            removeLoop()
            video.stop()
        }
    }

    private func loadVideo() async {
        guard player == nil else { return }
        guard let loadedPlayer = await video.loadVideo() else { return }

        player = loadedPlayer
        aspectRatio = getAspectRatio(from: loadedPlayer)
        setupLoop(for: loadedPlayer)
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

private struct PlayerView: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> PlayerUIView {
        PlayerUIView(player: player)
    }
    
    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.playerLayer.player = player
    }
}

private class PlayerUIView: UIView {
    let playerLayer = AVPlayerLayer()
    
    init(player: AVPlayer) {
        super.init(frame: .zero)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect
        layer.addSublayer(playerLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}
