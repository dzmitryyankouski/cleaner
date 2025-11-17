import Foundation
import Observation

@Observable
class PhotoLibrary {
    var indexing: Bool = false
    var indexed: Int = 0
    var total: Int = 0
    
    var similarGroups: [PhotoGroupModel] = []
    var similarPhotos: [PhotoModel] = []
    var similarPhotosFileSize: Int64 = 0

    var duplicatesGroups: [PhotoGroupModel] = []
    var duplicatesPhotos: [PhotoModel] = []
    var duplicatesPhotosFileSize: Int64 = 0

    var screenshots: [PhotoModel] = []
    var screenshotsFileSize: Int64 = 0

    private let photoService: PhotoService

    init(photoService: PhotoService) {
        self.photoService = photoService

        Task {
            await loadPhotos()
        }
    }

    func loadPhotos() async {
        print("🔍 Загрузка фотографий")
        indexing = true

        let photos = await photoService.getAllPhotos()

         total = photos.count
        
        await photoService.indexPhotos { [weak self] in
            self?.indexed += 1
        }

        print("🔍 Группировка фотографий")
        
        await photoService.groupSimilar(threshold: 0.85)
        await photoService.groupDuplicates(threshold: 0.99)

        similarGroups = photoService.getSimilarGroups()
        similarPhotos = photoService.getSimilarPhotos()
        similarPhotosFileSize = similarPhotos.reduce(0) { $0 + ($1.fileSize ?? 0) }

        duplicatesGroups = photoService.getDuplicatesGroups()
        duplicatesPhotos = photoService.getDuplicatesPhotos()
        duplicatesPhotosFileSize = duplicatesPhotos.reduce(0) { $0 + ($1.fileSize ?? 0) }

        screenshots = photoService.getScreenshots()
        screenshotsFileSize = screenshots.reduce(0) { $0 + ($1.fileSize ?? 0) }

        indexing = false

        print("✅ Фотографии загружены")
    }

    func reset() {
        photoService.reset()

        similarGroups = []
        similarPhotos = []
        similarPhotosFileSize = 0

        duplicatesGroups = []
        duplicatesPhotos = []
        duplicatesPhotosFileSize = 0
    }
}
