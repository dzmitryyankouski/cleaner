import Foundation
import SwiftUI

// MARK: - App Dependency Container

/// Контейнер зависимостей приложения
final class AppDependencyContainer {
    
    // MARK: - Singleton
    
    static let shared = AppDependencyContainer()
    
    // MARK: - Properties
    
    private let serviceFactory: ServiceFactory
    private let useCaseFactory: UseCaseFactory
    
    // MARK: - Initialization
    
    private init() {
        self.serviceFactory = ServiceFactory.shared
        self.useCaseFactory = UseCaseFactory(serviceFactory: serviceFactory)
    }
    
    /// Создает PhotoViewModel с правильными зависимостями
    @MainActor
    func makePhotoViewModel() -> PhotoViewModel? {
        guard let indexPhotosUseCase = useCaseFactory.makeIndexPhotosUseCase(),
              let searchPhotosUseCase = useCaseFactory.makeSearchPhotosUseCase() else {
            print("❌ Не удалось создать Use Cases для PhotoViewModel")
            return nil
        }
        
        return PhotoViewModel(
            indexPhotosUseCase: indexPhotosUseCase,
            groupSimilarPhotosUseCase: useCaseFactory.makeGroupSimilarPhotosUseCase(),
            searchPhotosUseCase: searchPhotosUseCase
        )
    }
    
    /// Создает VideoViewModel с правильными зависимостями
    @MainActor
    func makeVideoViewModel() -> VideoViewModel? {
        guard let indexVideosUseCase = useCaseFactory.makeIndexVideosUseCase() else {
            print("❌ Не удалось создать Use Cases для VideoViewModel")
            return nil
        }
        
        return VideoViewModel(
            indexVideosUseCase: indexVideosUseCase,
            groupSimilarVideosUseCase: useCaseFactory.makeGroupSimilarVideosUseCase()
        )
    }

    @MainActor
    func makePhotoLibrary() -> PhotoLibrary? {
        guard let photoService = serviceFactory.makePhotoService() else {
            print("❌ Не удалось создать PhotoService для PhotoLibrary")
            return nil
        }

        return PhotoLibrary(photoService: photoService)
    }
    
    @MainActor
    func makePhotoPreview() -> PhotoPreview {
        return PhotoPreview()
    }

}

