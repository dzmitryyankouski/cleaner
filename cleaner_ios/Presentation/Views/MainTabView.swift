import SwiftUI


struct MainTabView: View {
    var body: some View {
        ZStack {
            TabView {
                Tab {
                    PhotosTabView()
                } label: {
                    Label("Фотографии", systemImage: "photo.stack")
                }

                Tab {
                    VideosTabView()
                } label: {
                    Label("Видео", systemImage: "video")
                }
                
                Tab(role: .search) {
                    SearchTabView()
                } label: {
                    Label("Поиск", systemImage: "magnifyingglass")
                }
            }
            .accentColor(.green)
        }
    }
}
