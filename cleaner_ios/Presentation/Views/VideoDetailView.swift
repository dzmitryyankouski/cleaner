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
                VideoPlayerView(video: video)
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .navigationTitle("Группа (\(videos.count))")
        .navigationBarTitleDisplayMode(.inline)
        .navigationTransition(.zoom(sourceID: selectedVideoId ?? currentVideoId, in: namespace))
        .onAppear {
            
        }
        .onDisappear {
            
        }
        .onChange(of: selectedVideoId) { oldValue, newValue in
            
        }
    }
}
