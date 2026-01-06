import SwiftUI
import Photos

struct VideoGrid: View {
    let videos: [VideoModel]
    var namespace: Namespace.ID

    @Environment(\.videoLibrary) var videoLibrary
    @State private var selectedVideo: VideoModel? = nil

    let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 1) {
            ForEach(videos, id: \.id) { video in
                VideoThumbnail(video: video)
                    .frame(width: UIScreen.main.bounds.width / 3 - (2 / 3), height: UIScreen.main.bounds.width / 2)
                    .clipped()
                    .overlay(
                        Group {
                            if videoLibrary?.selectedVideos.contains(video) ?? false {
                                Color.white.opacity(0.5)
                            }
                        }
                        .transaction { $0.animation = nil }
                    )
                    .onTapGesture {
                        if videoLibrary?.selectedVideos.isEmpty ?? true {
                            selectedVideo = video
                        } else {
                            withAnimation {
                                videoLibrary?.select(video: video)
                            }
                        }
                    }
                    .highPriorityGesture(
                        LongPressGesture(minimumDuration: 0.3)
                            .onEnded { _ in
                                withAnimation {
                                    videoLibrary?.select(video: video)
                                }
                            }
                    )
                    .id(video.id)
                    .matchedTransitionSource(id: video.id, in: namespace)
            }
        }
        .fullScreenCover(item: $selectedVideo) { video in
            VideoDetailView(videos: videos, currentItem: video, namespace: namespace)
        }
    }
}
