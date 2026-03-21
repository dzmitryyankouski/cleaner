import SwiftUI
import SwiftData

@main
struct CleanerApp: App {
    private let appContainer = AppDependencyContainer.shared

    var body: some Scene {
        WindowGroup {
            AppRootView(container: appContainer)
        }
        .modelContainer(appContainer.getModelContainer())
    }
}

struct PhotoLibraryKey: EnvironmentKey {
    static let defaultValue: PhotoLibrary? = nil
}

struct VideoLibraryKey: EnvironmentKey {
    static let defaultValue: VideoLibrary? = nil
}

struct MediaLibraryKey: EnvironmentKey {
    static let defaultValue: MediaLibrary? = nil
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

    var mediaLibrary: MediaLibrary? {
        get { self[MediaLibraryKey.self] }
        set { self[MediaLibraryKey.self] = newValue }
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
    @State private var mediaLibrary: MediaLibrary?
    @State private var settings: Settings?
    @State private var isInitialized = false

    var body: some View {
        Group {
            if isInitialized {
                MainView()
//                     MainScreen()
                    .environment(\.photoLibrary, photoLibrary)
                    .environment(\.videoLibrary, videoLibrary)
                    .environment(\.mediaLibrary, mediaLibrary)
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
        settings = container.makeSettings()
        photoLibrary = container.makePhotoLibrary()
        videoLibrary = container.makeVideoLibrary()
        if let photoLibrary, let videoLibrary {
            mediaLibrary = MediaLibrary(photoLibrary: photoLibrary, videoLibrary: videoLibrary)
        }

        isInitialized = true
    }
}
