import SwiftUI


struct MainTabView: View {
    @StateObject var photoViewModel: PhotoViewModel
    @StateObject var videoViewModel: VideoViewModel
    @StateObject var settingsViewModel: SettingsViewModel
    @Namespace private var photoPreviewNamespace

    
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
            .accentColor(.blue)
        }
        .overlay {
            PhotoPreviewModal()
        }
        .environment(\.photoPreviewNamespace, photoPreviewNamespace)
    }
}
