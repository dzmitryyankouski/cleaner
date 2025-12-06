import SwiftUI
import Photos
import AVKit

struct VideoDetailView: View {
    let videos: [VideoModel]
    let currentItem: VideoModel
    var namespace: Namespace.ID

    @State private var selectedItem: VideoModel? = nil
    @State private var players: [String: AVPlayer] = [:]
    @State private var loadedVideoIds: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedItem) {
                ForEach(videos, id: \.id) { video in
                    VStack {
                        VideoPlayerCard(video: video, isSelected: selectedItem?.id == video.id)
                    }
                    .id(video.id)
                    .tag(video)
                    .padding(.bottom, 100)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onAppear {
                selectedItem = currentItem
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationTransition(.zoom(sourceID: selectedItem?.id ?? currentItem.id, in: namespace))
        .ignoresSafeArea(.all)
    }
}
