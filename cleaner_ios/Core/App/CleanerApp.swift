import SwiftUI
import SwiftData
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes

// MARK: - Cleaner App

@main
struct CleanerApp: App {
    
    // MARK: - Properties
    
    private let appContainer = AppDependencyContainer.shared
    
    // MARK: - Initialization
    
    init() {
        setupAppCenter()
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            AppRootView(container: appContainer)
        }
        .modelContainer(for: [PhotoModel.self, PhotoGroupModel.self], inMemory: false)
    }
    
    // MARK: - Private Methods
    
    private func setupAppCenter() {
        AppCenter.start(
            withAppSecret: "6acbaba5-f2ac-484e-87fd-5fc59675eeda",
            services: [Analytics.self, Crashes.self]
        )
    }
}

// MARK: - Environment Key для PhotoLibrary

/// Environment key для хранения PhotoLibrary
struct PhotoLibraryKey: EnvironmentKey {
    static let defaultValue: PhotoLibrary? = nil
}

extension EnvironmentValues {
    var photoLibrary: PhotoLibrary? {
        get { self[PhotoLibraryKey.self] }
        set { self[PhotoLibraryKey.self] = newValue }
    }
}

// MARK: - App Root View

struct AppRootView: View {
    let container: AppDependencyContainer
    @State private var photoViewModel: PhotoViewModel?
    @State private var videoViewModel: VideoViewModel?
    @State private var settingsViewModel: SettingsViewModel?
    @State private var photoLibrary: PhotoLibrary?
    @State private var isInitialized = false
    
    var body: some View {
        Group {
            if isInitialized {
                if let photoViewModel = photoViewModel,
                   let videoViewModel = videoViewModel,
                   let settingsViewModel = settingsViewModel {
                    MainTabView(
                        photoViewModel: photoViewModel,
                        videoViewModel: videoViewModel,
                        settingsViewModel: settingsViewModel
                    )
                    .environment(\.photoLibrary, photoLibrary)
                } else {
                    ErrorView(
                        message: "Не удалось инициализировать приложение. Пожалуйста, перезапустите приложение."
                    )
                }
            } else {
                ProgressView("Инициализация...")
            }
        }
        .task {
            await initializeViewModels()
        }
    }
    
    @MainActor
    private func initializeViewModels() {
        // Создаём все ViewModels независимо
        photoViewModel = container.makePhotoViewModel()
        videoViewModel = container.makeVideoViewModel()
        settingsViewModel = container.makeSettingsViewModel()

        photoLibrary = container.makePhotoLibrary()
        
        isInitialized = true
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Ошибка")
                .font(.title)
                .fontWeight(.bold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

