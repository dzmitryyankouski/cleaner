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
        .modelContainer(appContainer.getModelContainer())
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

// MARK: - Environment Key для VideoLibrary

/// Environment key для хранения VideoLibrary
struct VideoLibraryKey: EnvironmentKey {
    static let defaultValue: VideoLibrary? = nil
}

// MARK: - Environment Key для Settings

struct SettingsKey: EnvironmentKey {
    static let defaultValue: Settings? = nil
}

extension EnvironmentValues {
    var photoLibrary: PhotoLibrary? {
        get { self[PhotoLibraryKey.self] }
        set { self[PhotoLibraryKey.self] = newValue }
    }

    var videoLibrary: VideoLibrary? {
        get { self[VideoLibraryKey.self] }
        set { self[VideoLibraryKey.self] = newValue }
    }

    var settings: Settings? {
        get { self[SettingsKey.self] }
        set { self[SettingsKey.self] = newValue }
    }
}

// MARK: - App Root View

struct AppRootView: View {
    let container: AppDependencyContainer
    @State private var photoLibrary: PhotoLibrary?
    @State private var videoLibrary: VideoLibrary?
    @State private var settings: Settings?
    @State private var isInitialized = false
    
    var body: some View {
        Group {
            if isInitialized {
                if let settings = settings {
                    MainTabView()
                        .environment(\.photoLibrary, photoLibrary)
                        .environment(\.videoLibrary, videoLibrary)
                        .environment(\.settings, settings)
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
        photoLibrary = container.makePhotoLibrary()
        videoLibrary = container.makeVideoLibrary()
        
        settings = container.makeSettings()

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

