import SwiftUI

struct AppView: View {
    @StateObject private var photoService = PhotoService.shared
    @StateObject private var videoService = VideoService.shared
    
    var body: some View {
        TabView {
            PhotosView(photoService: photoService)
                .tabItem {
                    Image(systemName: "photo.stack")
                    Text("Фотографии")
                }
            
            VideosView(videoService: videoService)
                .tabItem {
                    Image(systemName: "video")
                    Text("Видео")
                }

            FilesView()
                .tabItem {
                    Image(systemName: "folder")
                    Text("Файлы")
                }
            
            SearchView(photoService: photoService)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Поиск")
                }

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Настройки")
                }
        }
        .accentColor(.blue)
    }
}
