import Photos
import SwiftUI

struct VideoDetailHeader: View {
    // MARK: - Environment
    @Environment(\.videoLibrary) var videoLibrary
    @Environment(\.dismiss) var dismiss
    
    // MARK: - Bindings
    @Binding var videos: [VideoModel]
    @Binding var selectedItem: VideoModel?
    
    // MARK: - Private State
    @State private var isProcessing = false

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
                        guard let video = selectedItem else { return }
                        handleDelete(video: video)
                    }
                ) {
                    Label("Remove", systemImage: "trash")
                }
                .disabled(selectedItem == nil || isProcessing)
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

