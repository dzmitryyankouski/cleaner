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
                Tab {
                    PhotosTabView()
                        .environmentObject(photoViewModel)
                } label: {
                    Label("Фотографии", systemImage: "photo.stack")
                }

                Tab {
                    VideosTabView()
                        .environmentObject(videoViewModel)
                } label: {
                    Label("Видео", systemImage: "video")
                }
                
                Tab(role: .search) {
                    SearchTabView()
                        .environmentObject(photoViewModel)
                }
            }
            .accentColor(.blue)
            
            PhotoPreview()
                .environmentObject(photoViewModel)
        }
        .environment(\.photoPreviewNamespace, photoPreviewNamespace)
    }
}
