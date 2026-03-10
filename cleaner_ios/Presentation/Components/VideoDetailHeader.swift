import Photos
import SwiftUI

struct VideoDetailHeader: View {
    // MARK: - Environment
    @Environment(\.videoLibrary) var videoLibrary
    @Environment(\.dismiss) var dismiss
    
    // MARK: - Bindings
    @Binding var items: [MediaItem]
    @Binding var selectedItem: MediaItem?
    
    // MARK: - Private State
    @State private var isProcessing = false

    private var selectedVideo: VideoModel? {
        guard case .video(let video) = selectedItem else { return nil }
        return video
    }

    var body: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .frame(width: 45, height: 45)
                    .font(.system(size: 18))
                    .foregroundColor(.black)
                    .glassEffect()
            }

            Spacer()

            Menu {
                Button(
                    role: .destructive,
                    action: {
                        guard let video = selectedVideo else { return }
                        handleDelete(video: video)
                    }
                ) {
                    Label("Remove", systemImage: "trash")
                }
                .disabled(selectedVideo == nil || isProcessing)
            } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 45, height: 45)
                    .font(.system(size: 18))
                    .foregroundColor(.black)
                    .glassEffect()
                    .padding(10)
            }
            .disabled(isProcessing)
        }
        .padding(.horizontal, 10)
    }

    // MARK: - Private Methods
    private func handleDelete(video: VideoModel) {
        isProcessing = true

        Task {
            let index = items.firstIndex { $0.id == video.id }
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
                        items.remove(at: index)

                        if items.isEmpty {
                            dismiss()
                        } else if index < items.count {
                            selectedItem = items[index]
                        } else if index > 0 {
                            selectedItem = items[index - 1]
                        } else {
                            selectedItem = items.first
                        }
                    }
                }
            case .failure:
                await MainActor.run {
                    isProcessing = false
                }
            }
        }
    }
}

