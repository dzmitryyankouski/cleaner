import Foundation

// MARK: - Group Similar Videos Use Case

/// Use Case для группировки похожих видео
final class GroupSimilarVideosUseCase {
    
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
    
    // MARK: - Public Methods
    
    /// Группирует видео по схожести используя настройки
    func groupSimilar(videos: [Video]) async -> [MediaGroup<Video>] {
        return await group(videos: videos, threshold: settingsProvider.getSettings().videoSimilarityThreshold)
    }

    // MARK: - Private Methods
    
    /// Группирует видео по схожести с указанным порогом
    private func group(videos: [Video], threshold: Float) async -> [MediaGroup<Video>] {
        guard !videos.isEmpty else { return [] }
        
        // Фильтруем видео с валидными эмбедингами
        let validVideos = videos.filter { !$0.embedding.isEmpty }
        guard !validVideos.isEmpty else { return [] }
        
        // Проверяем размерность эмбедингов
        let standardDim = validVideos[0].embedding.dimension
        let consistentVideos = validVideos.filter { $0.embedding.dimension == standardDim }
        
        guard consistentVideos.count > 1 else { return [] }
        
        let embeddings = consistentVideos.map { $0.embedding.values }
        let groupIndices = await clusteringService.groupEmbeddings(embeddings, threshold: threshold)
        
        // Конвертируем индексы в группы видео
        let videoGroups = groupIndices.compactMap { indices -> MediaGroup<Video>? in
            let groupVideos = indices.compactMap { index in
                consistentVideos.indices.contains(index) ? consistentVideos[index] : nil
            }
            
            guard groupVideos.count > 1 else { return nil }
            return MediaGroup(items: groupVideos)
        }
        
        // Сортируем группы по дате (от новых к старым)
        return sortGroupsByDate(videoGroups)
    }
    
    private func sortGroupsByDate(_ groups: [MediaGroup<Video>]) -> [MediaGroup<Video>] {
        groups.sorted { group1, group2 in
            guard let date1 = getLatestDate(in: group1),
                  let date2 = getLatestDate(in: group2) else {
                return false
            }
            return date1 > date2
        }
    }
    
    private func getLatestDate(in group: MediaGroup<Video>) -> Date? {
        group.items.compactMap { $0.creationDate }.max()
    }
}

