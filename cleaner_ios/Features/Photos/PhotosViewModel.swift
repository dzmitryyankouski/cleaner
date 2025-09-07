import Foundation
import PhotosUI
import SwiftUI

@MainActor
class PhotosViewModel: ObservableObject {
    @Published var selectedImages: [UIImage] = []

    var imageEmbeddingService = ImageEmbeddingService()
    var clusterService = ClusterService()
    var embeddings: [[Float]] = []
    var groups: [ClusterImageGroup] = []

    func onSelectImages(items: [PhotosPickerItem]) async {
        selectedImages = await loadSelectedImages(items: items)
        embeddings = await imageEmbeddingService.generateEmbeddings(from: selectedImages)

        groups = await clusterService.getImageGroups(for: embeddings)

        print("🔍 Groups: \(groups)")
    }

    private func loadSelectedImages(items: [PhotosPickerItem]) async -> [UIImage] {
        var images: [UIImage] = []

        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                images.append(image)
            }
        }

        return images
    }
}
