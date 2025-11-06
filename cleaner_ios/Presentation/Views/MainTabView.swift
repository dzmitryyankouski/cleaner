import SwiftUI

// MARK: - Environment Key для Namespace

/// Environment key для хранения namespace для анимаций превью фото
struct PhotoPreviewNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var photoPreviewNamespace: Namespace.ID? {
        get { self[PhotoPreviewNamespaceKey.self] }
        set { self[PhotoPreviewNamespaceKey.self] = newValue }
    }
}

// MARK: - Main Tab View

/// Главный таб-бар приложения
struct MainTabView: View {
    
    // MARK: - Properties
    
    @StateObject var photoViewModel: PhotoViewModel
    @StateObject var videoViewModel: VideoViewModel
    @StateObject var settingsViewModel: SettingsViewModel

    @Namespace private var photoPreviewNamespace
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            PhotoPreview(viewModel: photoViewModel)

        TabView {
            PhotosTabView(viewModel: photoViewModel)
                .tabItem {
                    Label("Фотографии", systemImage: "photo.stack")
                }
            
            VideosTabView(viewModel: videoViewModel)
                .tabItem {
                    Label("Видео", systemImage: "video")
                }
            
            SearchTabView(viewModel: photoViewModel)
                .tabItem {
                    Label("Поиск", systemImage: "magnifyingglass")
                }
            
            SettingsTabView(viewModel: settingsViewModel)
                .tabItem {
                    Label("Настройки", systemImage: "gearshape")
                }
        }
        .environment(\.photoPreviewNamespace, photoPreviewNamespace)
        .accentColor(.blue)
        }
    }
}
