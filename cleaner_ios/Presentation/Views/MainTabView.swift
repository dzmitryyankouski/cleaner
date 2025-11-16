import SwiftUI


struct MainTabView: View {
    @StateObject var photoViewModel: PhotoViewModel
    @StateObject var videoViewModel: VideoViewModel

    
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
                        .environmentObject(videoViewModel)
                } label: {
                    Label("Видео", systemImage: "video")
                }
                
                Tab(role: .search) {
                    SearchTabView()
                        .environmentObject(photoViewModel)
                }
            }
            .accentColor(.green)
        }
    }
}
