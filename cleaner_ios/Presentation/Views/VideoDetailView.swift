import SwiftUI
import Photos
import AVKit

struct VideoDetailView: View {
    let videos: [VideoModel]
    let currentVideoId: String
    var namespace: Namespace.ID
    @State private var selectedVideoId: String? = nil
    @State private var players: [String: AVPlayer] = [:]
    @State private var loadedVideoIds: Set<String> = []

    var body: some View {
        TabView(selection: $selectedVideoId) {
            ForEach(videos, id: \.id) { video in
                if let player = players[video.id] {
                    VideoPlayerView(video: video, player: player)
                        .id(video.id)
                        .tag(video.id)
                } else {
                    Color.black
                        .overlay(ProgressView().tint(.white))
                        .id(video.id)
                        .tag(video.id)
                }
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .navigationTitle("Группа (\(videos.count))")
        .navigationBarTitleDisplayMode(.inline)
        .navigationTransition(.zoom(sourceID: currentVideoId, in: namespace))
        .onAppear {
            selectedVideoId = currentVideoId
            loadPlayers()
        }
        .onDisappear {
            // Останавливаем все плееры при закрытии
            players.values.forEach { $0.pause() }
            players.removeAll()
        }
        .onChange(of: selectedVideoId) { oldValue, newValue in
            // Останавливаем предыдущее видео
            if let oldId = oldValue, let oldPlayer = players[oldId] {
                oldPlayer.pause()
            }
            // Запускаем новое видео
            if let newId = newValue, let newPlayer = players[newId] {
                newPlayer.play()
            }
        }
    }
    
    private func loadPlayers() {
        for video in videos {
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [video.id], options: nil)
            guard let asset = assets.firstObject else { continue }
            
            let player = AVPlayer()
            players[video.id] = player
            
            // Загружаем видео асинхронно
            Task {
                let options = PHVideoRequestOptions()
                options.isNetworkAccessAllowed = true
                options.deliveryMode = .highQualityFormat
                
                PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                    DispatchQueue.main.async {
                        if let urlAsset = avAsset as? AVURLAsset {
                            let newPlayer = AVPlayer(url: urlAsset.url)
                            self.players[video.id] = newPlayer
                            self.loadedVideoIds.insert(video.id)
                            
                            // Если это текущее видео, начинаем воспроизведение
                            if video.id == self.selectedVideoId {
                                newPlayer.play()
                            }
                        }
                    }
                }
            }
        }
    }
}

struct VideoPlayerView: View {
    let video: VideoModel
    let player: AVPlayer
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            if player.currentItem != nil {
                isLoading = false
            } else {
                // Ждем загрузки
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isLoading = false
                }
            }
        }
        .onChange(of: player.currentItem) { oldValue, newValue in
            if newValue != nil {
                isLoading = false
            }
        }
    }
}

