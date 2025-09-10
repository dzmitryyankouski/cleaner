import SwiftUI

struct AppView: View {
    var body: some View {
        TabView {
            PhotosView()
                .tabItem {
                    Image(systemName: "photo.stack")
                    Text("Фотографии")
                }
            
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Поиск")
                }
        }
        .accentColor(.blue)
    }
}
