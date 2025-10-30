import Foundation
import SwiftUI

// MARK: - Video View Model

/// ViewModel для управления видео
@MainActor
final class VideoViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var videos: [Video] = []
    @Published var indexed: Int = 0
    @Published var total: Int = 0
    @Published var groupsSimilar: [MediaGroup<Video>] = []
    @Published var isLoading: Bool = false
    @Published var indexing: Bool = false
    
    // MARK: - Private Properties
    
    private let indexVideosUseCase: IndexVideosUseCase
    private let groupSimilarVideosUseCase: GroupSimilarVideosUseCase
    
    // MARK: - Initialization
    
    init(
        indexVideosUseCase: IndexVideosUseCase,
        groupSimilarVideosUseCase: GroupSimilarVideosUseCase
    ) {
        self.indexVideosUseCase = indexVideosUseCase
        self.groupSimilarVideosUseCase = groupSimilarVideosUseCase
        
        Task {
            await loadAndIndexVideos()
        }
    }
    
    // MARK: - Public Methods
    
    func refreshVideos() async {
        videos.removeAll()
        groupsSimilar.removeAll()
        indexed = 0
        
        await loadAndIndexVideos()
    }
    
    // MARK: - Computed Properties
    
    var videosCount: Int {
        videos.count
    }
    
    var groupsCount: Int {
        groupsSimilar.count
    }
    
    var totalFileSize: Int64 {
        videos.reduce(0) { $0 + $1.fileSize.bytes }
    }
    
    var formattedTotalFileSize: String {
        FileSize(bytes: totalFileSize).formatted
    }
    
    // MARK: - Private Methods
    
    private func loadAndIndexVideos() async {
        isLoading = true
        indexing = true
        
        // Индексация видео
        let result = await indexVideosUseCase.execute { [weak self] total, indexed, video in
            self?.indexed = indexed
            self?.total = total
        }
        
        switch result {
        case .success(let indexedVideos):
            self.videos = indexedVideos.sorted { $0.fileSize.bytes > $1.fileSize.bytes }
            
            // Группируем похожие видео
            await createSimilarGroups()
            
        case .failure(let error):
            print("❌ Ошибка индексации видео: \(error.localizedDescription)")
        }
        
        isLoading = false
        indexing = false
    }
    
    private func createSimilarGroups() async {
        let groups = await groupSimilarVideosUseCase.groupSimilar(videos: videos)
        
        self.groupsSimilar = groups
        print("📁 Создано \(groups.count) групп похожих видео")
    }
}

