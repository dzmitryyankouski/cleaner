import SwiftUI

struct AppView: View {
    @StateObject private var photoService = PhotoService.shared
    
    var body: some View {
        TabView {
            PhotosView(photoService: photoService)
                .tabItem {
                    Image(systemName: "photo.stack")
                    Text("Фотографии")
                }
            
            VideosView()
                .tabItem {
                    Image(systemName: "video")
                    Text("Видео")
                }
            
            SearchView(photoService: photoService)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Поиск")
                }
        }
        .accentColor(.blue)
    }
}
