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
        VStack(spacing: 0) {
            TabView(selection: $selectedVideoId) {
                ForEach(videos, id: \.id) { video in
                    VStack {
                        VideoPlayerView(video: video, isSelected: selectedVideoId == video.id)
                    }
                    .id(video.id)
                    .tag(video.id)
                    .padding(.bottom, 100)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onAppear {
                selectedVideoId = currentVideoId
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationTransition(.zoom(sourceID: selectedVideoId ?? currentVideoId, in: namespace))
        .ignoresSafeArea(.all)
    }
}
