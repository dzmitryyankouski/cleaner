import Foundation
import PhotosUI
import SwiftUI

@MainActor
class PhotosViewModel: ObservableObject {
    @Published var selectedImages: [UIImage] = []
    @Published var groups: [[Int]] = []

    var imageEmbeddingService = ImageEmbeddingService()
    var clusterService = ClusterService()
    var embeddings: [[Float]] = []

    func onSelectImages(items: [PhotosPickerItem]) async {
        print("start loading selected images")
        selectedImages = await loadSelectedImages(items: items)
        print("Selected images loaded")

        embeddings = await imageEmbeddingService.generateEmbeddings(from: selectedImages)
        print("Embeddings generated")

        groups = await clusterService.getImageGroups(for: embeddings, threshold: 0.85)
        print("Groups generated")
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
