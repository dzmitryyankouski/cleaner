import SwiftUI

struct VideoThumbnail: View {
    let video: VideoModel
    
    @State private var image: UIImage?

    private var formattedDuration: String {
        let totalSeconds = Int(video.duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .overlay(alignment: .bottomTrailing) {
                        Text(formattedDuration)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 25)
                    }
            } else {
                Color.gray.opacity(0.3)
                    .task {
                        guard let loaded = await video.loadPreview() else { return }
                        image = loaded
                    }
            }
        }
    }
}