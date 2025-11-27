import SwiftUI
import Photos
import AVFoundation

struct VideoGridView: View {
    let videos: [VideoModel]
    @Binding var navigationPath: NavigationPath
    var namespace: Namespace.ID

    let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 1) {
            ForEach(videos, id: \.id) { video in
                VideoThumbnailView(video: video)
                    .frame(width: UIScreen.main.bounds.width / 3 - (2 / 3), height: UIScreen.main.bounds.width / 2)
                    .clipped()
                    .onTapGesture {
                        navigationPath.append(VideoGroupNavigationItem(videos: videos, currentVideoId: video.id))
                    }
                    .id(video.id)
                    .matchedTransitionSource(id: video.id, in: namespace)
            }
        }
    }
}

struct VideoThumbnailView: View {
    let video: VideoModel

    @State private var thumbnail: UIImage?
    @State private var isLoading = false
    
    init(video: VideoModel) {
        self.video = video
    }

    var body: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.gray.opacity(0.3)
                    .onAppear {
                        loadThumbnail()
                    }
            }
        }
    }
    
    private func loadThumbnail() {
        guard !isLoading && thumbnail == nil else { return }
        isLoading = true

        Task {
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [video.id], options: nil)
            guard let asset = assets.firstObject else {
                await MainActor.run {
                    isLoading = false
                }
                return
            }
            
            await loadThumbnailFromAsset(asset)
        }
    }
    
    private func loadThumbnailFromAsset(_ asset: PHAsset) async {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = false
        
        await withCheckedContinuation { continuation in
            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                guard let avAsset = avAsset else {
                    Task { @MainActor in
                        self.isLoading = false
                    }
                    continuation.resume()
                    return
                }
                
                Task {
                    await self.generateThumbnail(from: avAsset)
                    continuation.resume()
                }
            }
        }
    }
    
    private func generateThumbnail(from avAsset: AVAsset) async {
        let imageGenerator = AVAssetImageGenerator(asset: avAsset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceAfter = .zero
        imageGenerator.requestedTimeToleranceBefore = .zero
        
        let targetSize = CGSize(width: 300, height: 400)
        imageGenerator.maximumSize = targetSize
        
        do {
            let time = CMTime(seconds: 0.0, preferredTimescale: 600)
            let cgImage = try await imageGenerator.image(at: time).image
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.thumbnail = UIImage(cgImage: cgImage)
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.isLoading = false
                }
            }
        }
    }
}