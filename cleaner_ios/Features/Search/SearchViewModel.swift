import Foundation
import Photos
import UIKit

@MainActor
class SearchViewModel: ObservableObject {
    @Published var photos: [PHAsset] = []
    @Published var processedPhotosCount = 0
    @Published var isIndexing = false
    @Published var searchText: String = ""
    @Published var searchResults: [PHAsset] = []
    @Published var searchResultsWithScores: [(PHAsset, Float)] = []
    @Published var isSearching = false

    var clusterService = ClusterService()
    var imageEmbeddingService = ImageEmbeddingService()
    var translateService = TranslateService()

    init() {
        print("SearchViewModel init")

        Task {
            let status = await requestPhotoLibraryAccess()

            if status == .authorized || status == .limited {
                await loadPhotos()
                await indexPhotos()
            }
        }

        imageEmbeddingService.onPhotoProcessed = { [weak self] photo in
            Task { @MainActor in
                self?.processedPhotosCount = self?.imageEmbeddingService.processedPhotos.count ?? 0
            }
        }
    }
    
    private func requestPhotoLibraryAccess() async -> PHAuthorizationStatus {
        let currentStatus = PHPhotoLibrary.authorizationStatus()

        if currentStatus == .notDetermined {
            await PHPhotoLibrary.requestAuthorization(for: .readWrite)

            let newStatus = PHPhotoLibrary.authorizationStatus()

            if newStatus == .authorized || newStatus == .limited {
                return newStatus
            }
        }

        return currentStatus
    }
    
    private func loadPhotos() async {
        let fetchResult = PHAsset.fetchAssets(with: .image, options: nil)
        var assets: [PHAsset] = []
        
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
        self.photos = assets
    }

    private func indexPhotos() async {
        isIndexing = true
        await imageEmbeddingService.indexPhotos(photos: photos)
        isIndexing = false
    }

    func searchImages() async {
        guard !searchText.isEmpty else { return }
        
        print("🔍 Поиск изображений: \(searchText)")
        
        isSearching = true

        let translatedText = await translateService.translate(text: searchText)

        print("🔍 Переведенный текст: \(translatedText)")
        
        let results = await imageEmbeddingService.findSimilarPhotos(query: translatedText)
        
        // Сохраняем результаты с оценками сходства (уже отсортированы по убыванию)
        searchResultsWithScores = results.map { ($0.0.asset, $0.1) }
        searchResults = results.map { $0.0.asset }
        isSearching = false
        
        for (index, result) in results.enumerated() {
            print("  \(index + 1). Сходство: \(String(format: "%.3f", result.1))")
        }
    }
}
