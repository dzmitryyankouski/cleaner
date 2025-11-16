import SwiftUI

struct PhotoDetailView: View {
    let photo: PhotoModel
    var namespace: Namespace.ID

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 16) {
                if let asset = photo.asset {
                    PhotoView(
                        photo: photo, quality: .high, contentMode: .fit
                    )
                }
            }
        }
        .navigationTitle("Фото")
        .navigationBarTitleDisplayMode(.inline)
        .navigationTransition(.zoom(sourceID: photo.id, in: namespace))
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

