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
            TabView {
                PhotosTabView()
                    .tabItem {
                        Label("Фотографии", systemImage: "photo.stack")
                    }
                    .environmentObject(photoViewModel)
                
                VideosTabView()
                    .tabItem {
                        Label("Видео", systemImage: "video")
                    }
                    .environmentObject(videoViewModel)

                SearchTabView()
                    .tabItem {
                        Label("Поиск", systemImage: "magnifyingglass")
                    }
                    .environmentObject(photoViewModel)

                SettingsTabView()
                    .tabItem {
                        Label("Настройки", systemImage: "gearshape")
                    }
                    .environmentObject(settingsViewModel)

                TestTabView()
                    .tabItem {
                        Label("Тест", systemImage: "testtube")
                    }
            }
            .accentColor(.blue)
            
            PhotoPreview()
                .environmentObject(photoViewModel)
        }
        .environment(\.photoPreviewNamespace, photoPreviewNamespace)
    }
}
