import SwiftUI
import Photos
import AVKit

struct VideoDetailView: View {
    @State var videos: [VideoModel]
    let currentItem: VideoModel
    var namespace: Namespace.ID

    @Environment(\.videoLibrary) var videoLibrary
    @Environment(\.dismiss) var dismiss

    @State private var selectedItem: VideoModel? = nil
    @State private var players: [String: AVPlayer] = [:]
    @State private var loadedVideoIds: Set<String> = []
    @State private var isProcessing = false

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
        .navigationTitle(selectedItem?.id ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationTransition(.zoom(sourceID: selectedItem?.id ?? currentItem.id, in: namespace))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(
                        role: .destructive,
                        action: {
                            guard let selectedItem = selectedItem else { return }
                            handleDelete(video: selectedItem)
                        }
                    ) {
                        Label("Remove", systemImage: "trash")
                    }
                    .disabled(selectedItem == nil || isProcessing)
                } label: {
                    Image(systemName: "ellipsis")
                }
                .disabled(isProcessing)
            }
        }
        .ignoresSafeArea(.all)
    }
    
    private func handleDelete(video: VideoModel) {
        isProcessing = true

        Task {
            let index = videos.firstIndex { $0.id == video.id }
            guard let result = await videoLibrary?.delete(videos: [video]) else {
                await MainActor.run {
                    isProcessing = false
                }
                return
            }

            switch result {
            case .success:
                await MainActor.run {
                    if let index = index {
                        isProcessing = false
                        videos.remove(at: index)

                        if videos.isEmpty {
                            dismiss()
                        } else if index < videos.count {
                            selectedItem = videos[index]
                        } else if index > 0 {
                            selectedItem = videos[index - 1]
                        } else {
                            selectedItem = videos.first
                        }
                    }
                }
            case .failure(let error):
                await MainActor.run {
                    isProcessing = false
                }
            }
        }
    }
}
