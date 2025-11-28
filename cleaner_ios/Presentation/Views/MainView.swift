import SwiftUI


struct MainView: View {
    var body: some View {
        ZStack {
            TabView {
                Tab {
                    PhotosView()
                } label: {
                    Label("Фотографии", systemImage: "photo.stack")
                }

                Tab {
                    VideosView()
                } label: {
                    Label("Видео", systemImage: "video")
                }
                
                Tab(role: .search) {
                    SearchView()
                } label: {
                    Label("Поиск", systemImage: "magnifyingglass")
                }
            }
            .accentColor(.green)
        }
    }
}
