import SwiftUI


struct MainTabView: View {
    @StateObject var photoViewModel: PhotoViewModel
    @StateObject var videoViewModel: VideoViewModel

    @State private var tabSelection = 0
    @State private var menuSelection = 0
    
    var body: some View {
        ZStack {
            TabView(selection: $tabSelection) {
                Tab(value: 0) {
                    PhotosTabView()
                } label: {
                    Label("Фотографии", systemImage: "photo.stack")
                }

                Tab(value: 1) {
                    VideosTabView()
                } label: {
                    Label("Видео", systemImage: "video")
                }
                
                Tab(value: 2, role: .search) {
                    SearchTabView(selectedMenu: $menuSelection)
                } label: {
                    Label("Поиск", systemImage: "magnifyingglass")
                }
            }
            .accentColor(.green)
            .onChange(of: tabSelection) { newValue in
                if newValue == 0 || newValue == 1 {
                    menuSelection = newValue
                }
            }
        }
    }
}
