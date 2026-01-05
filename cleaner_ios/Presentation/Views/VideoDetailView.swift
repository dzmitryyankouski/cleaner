import SwiftUI
import Photos
import AVKit

struct VideoDetailView: View {
    // MARK: - Environment
    @Environment(\.videoLibrary) var videoLibrary
    
    // MARK: - Parameters
    @State var videos: [VideoModel]
    let currentItem: VideoModel
    let namespace: Namespace.ID
    
    // MARK: - Private State
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
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onAppear {
                selectedItem = currentItem
            }
        }
        .overlay(
            VStack {
                VideoDetailHeader(videos: $videos, selectedItem: $selectedItem)

                Spacer()

                ThumbnailIndicator(items: videos, selectedItem: $selectedItem) { video in
                    VideoThumbnail(video: video)
                }
            }
        )
        .navigationTransition(.zoom(sourceID: selectedItem?.id ?? currentItem.id, in: namespace))
    }
}
