import Foundation
import SwiftUI

// MARK: - Photo View Model

/// ViewModel для управления фотографиями
@MainActor
final class PhotoViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var photos: [Photo] = []
    @Published var indexed: Int = 0
    @Published var total: Int = 0
    @Published var groupsSimilar: [MediaGroup<Photo>] = []
    @Published var groupsDuplicates: [MediaGroup<Photo>] = []
    @Published var indexing: Bool = false
    
    @Published var selectedPhotosForDeletion: Set<Int> = []
    @Published var selectedPhotosFileSize: Int64 = 0

    @Published var previewPhoto: Photo? = nil
    
    // MARK: - Private Properties
    
    private let indexPhotosUseCase: IndexPhotosUseCase
    private let groupSimilarPhotosUseCase: GroupSimilarPhotosUseCase
    private let searchPhotosUseCase: SearchPhotosUseCase
    
    // MARK: - Initialization
    
    init(
        indexPhotosUseCase: IndexPhotosUseCase,
        groupSimilarPhotosUseCase: GroupSimilarPhotosUseCase,
        searchPhotosUseCase: SearchPhotosUseCase
    ) {
        self.indexPhotosUseCase = indexPhotosUseCase
        self.groupSimilarPhotosUseCase = groupSimilarPhotosUseCase
        self.searchPhotosUseCase = searchPhotosUseCase
        
        Task {
            await loadAndIndexPhotos()
        }
    }
    
    // MARK: - Public Methods
    
    func search(text: String) async -> [Photo] {
        let result = await searchPhotosUseCase.search(
            query: text,
            photos: photos
        )
        
        switch result {
        case .success(let searchResults):
            return searchResults.map { $0.item }
        case .failure(let error):
            print("❌ Ошибка поиска: \(error.localizedDescription)")
            return []
        }
    }
    
    func refreshPhotos() async {
        photos.removeAll()
        groupsSimilar.removeAll()
        groupsDuplicates.removeAll()
        selectedPhotosForDeletion.removeAll()
        selectedPhotosFileSize = 0
        indexed = 0
        
        await loadAndIndexPhotos()
    }

    func setPreviewPhoto(for photo: Photo) {
        previewPhoto = photo
        print("previewPhoto: \(previewPhoto?.id)")
    }

    func clearPreviewPhoto() {
        previewPhoto = nil
    }
    
    func togglePhotoSelection(for photo: Photo) {
        if selectedPhotosForDeletion.contains(photo.index) {
            selectedPhotosForDeletion.remove(photo.index)
            selectedPhotosFileSize -= photo.fileSize.bytes
        } else {
            selectedPhotosFileSize += photo.fileSize.bytes
            selectedPhotosForDeletion.insert(photo.index)
        }
    }
    
    // MARK: - Computed Properties
    
    var totalPhotosCount: Int {
        photos.count
    }
    
    var totalFileSize: Int64 {
        photos.reduce(0) { $0 + $1.fileSize.bytes }
    }
    
    var formattedTotalFileSize: String {
        FileSize(bytes: totalFileSize).formatted
    }
    
    var formattedSelectedFileSize: String {
        FileSize(bytes: selectedPhotosFileSize).formatted
    }
    
    // MARK: - Private Methods
    
    private func loadAndIndexPhotos() async {
        indexing = true
        
        // Индексация фотографий
        let result = await indexPhotosUseCase.execute { [weak self] total, indexed, photo in
            self?.indexed = indexed
            self?.total = total
        }
        
        switch result {
        case .success(let indexedPhotos):
            self.photos = indexedPhotos
            
            // Группируем похожие фотографии
            await createSimilarGroups()
            
            // Группируем дубликаты
            await createDuplicateGroups()
            
        case .failure(let error):
            print("❌ Ошибка индексации: \(error.localizedDescription)")
        }
        
        indexing = false
    }
    
    private func createSimilarGroups() async {
        let groups = await groupSimilarPhotosUseCase.groupSimilar(photos: photos)
        
        self.groupsSimilar = groups
        
        // Автоматически выбираем фото для удаления (кроме первого в каждой группе)
        for group in groups {
            for (index, photo) in group.items.enumerated() where index > 0 {
                togglePhotoSelection(for: photo)
            }
        }
    }
    
    private func createDuplicateGroups() async {
        let groups = await groupSimilarPhotosUseCase.groupDuplicates(photos: photos)
        
        self.groupsDuplicates = groups
    }
}

