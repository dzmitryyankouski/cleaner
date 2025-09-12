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
            
            SearchView(photoService: photoService)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Поиск")
                }
        }
        .accentColor(.blue)
    }
}
