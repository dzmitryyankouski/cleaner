import SwiftUI

// MARK: - Main Tab View

/// Главный таб-бар приложения
struct MainTabView: View {
    
    // MARK: - Properties
    
    @StateObject var photoViewModel: PhotoViewModel
    @StateObject var videoViewModel: VideoViewModel
    @StateObject var settingsViewModel: SettingsViewModel
    
    // MARK: - Body
    
    var body: some View {
        TabView {
            PhotosTabView(viewModel: photoViewModel)
                .tabItem {
                    Label("Фотографии", systemImage: "photo.stack")
                }
            
            VideosTabView(viewModel: videoViewModel)
                .tabItem {
                    Label("Видео", systemImage: "video")
                }
            
            FilesTabView()
                .tabItem {
                    Label("Файлы", systemImage: "folder")
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
        .accentColor(.blue)
    }
}

// MARK: - Tab Views Placeholders

struct FilesTabView: View {
    var body: some View {
        NavigationView {
            Text("Файлы")
                .navigationTitle("Файлы")
        }
    }
}

