import Foundation

// MARK: - Group Similar Photos Use Case

/// Use Case для группировки похожих фотографий
final class GroupSimilarPhotosUseCase {
    
    // MARK: - Properties
    
    private let clusteringService: ClusteringServiceProtocol
    private let settingsProvider: SettingsProviderProtocol
    
    // MARK: - Initialization
    
    init(
        clusteringService: ClusteringServiceProtocol,
        settingsProvider: SettingsProviderProtocol
    ) {
        self.clusteringService = clusteringService
        self.settingsProvider = settingsProvider
    }

    func groupDuplicates(photos: [Photo]) async -> [MediaGroup<Photo>] {
        return await group(photos: photos, threshold: 0.99)
    }

    func groupSimilar(photos: [Photo]) async -> [MediaGroup<Photo>] {
        return await group(photos: photos, threshold: settingsProvider.getSettings().photoSimilarityThreshold)
    }
    
    /// Группирует фотографии по схожести с указанным порогом
    private func group(photos: [Photo], threshold: Float) async -> [MediaGroup<Photo>] {
        guard !photos.isEmpty else { return [] }
        
        let embeddings = photos.map { $0.embedding.values }
        let groupIndices = await clusteringService.groupEmbeddings(embeddings, threshold: threshold)
        
        // Конвертируем индексы в группы фото
        let photoGroups = groupIndices.compactMap { indices -> MediaGroup<Photo>? in
            let groupPhotos = indices.compactMap { index in
                photos.indices.contains(index) ? photos[index] : nil
            }
            
            guard groupPhotos.count > 1 else { return nil }
            return MediaGroup(items: groupPhotos)
        }
        
        // Сортируем группы по дате (от новых к старым)
        return sortGroupsByDate(photoGroups)
    }
    
    // MARK: - Private Methods
    
    private func sortGroupsByDate(_ groups: [MediaGroup<Photo>]) -> [MediaGroup<Photo>] {
        groups.sorted { group1, group2 in
            guard let date1 = getLatestDate(in: group1),
                  let date2 = getLatestDate(in: group2) else {
                return false
            }
            return date1 > date2
        }
    }
    
    private func getLatestDate(in group: MediaGroup<Photo>) -> Date? {
        group.items.compactMap { $0.asset.creationDate }.max()
    }
}

