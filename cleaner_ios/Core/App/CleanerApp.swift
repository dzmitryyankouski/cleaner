import SwiftUI
import SwiftData
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes

@main
struct CleanerApp: App {
    private let appContainer = AppDependencyContainer.shared
        
    init() {
        setupAppCenter()
    }
        
    var body: some Scene {
        WindowGroup {
            AppRootView(container: appContainer)
        }
        .modelContainer(appContainer.getModelContainer())
    }
        
    private func setupAppCenter() {
        AppCenter.start(
            withAppSecret: "6acbaba5-f2ac-484e-87fd-5fc59675eeda",
            services: [Analytics.self, Crashes.self]
        )
    }
}

struct PhotoLibraryKey: EnvironmentKey {
    static let defaultValue: PhotoLibrary? = nil
}

struct VideoLibraryKey: EnvironmentKey {
    static let defaultValue: VideoLibrary? = nil
}

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

struct AppRootView: View {
    let container: AppDependencyContainer
    @State private var photoLibrary: PhotoLibrary?
    @State private var videoLibrary: VideoLibrary?
    @State private var settings: Settings?
    @State private var isInitialized = false
    
    var body: some View {
        Group {
            if isInitialized {
                MainView()
                    .environment(\.photoLibrary, photoLibrary)
                    .environment(\.videoLibrary, videoLibrary)
                    .environment(\.settings, settings)
            } else {
                InitialView()
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
