import SwiftUI


struct MainTabView: View {
    @StateObject var photoViewModel: PhotoViewModel
    @StateObject var videoViewModel: VideoViewModel
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
            .accentColor(.green)
        }
        .overlay {
            PhotoPreviewModal()
        }
        .environment(\.photoPreviewNamespace, photoPreviewNamespace)
    }
}

struct Test: View {
    @State var isPresented: Bool = false
    @Namespace private var custom
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
               
            }
            .navigationTitle("Фотографии")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape") {
                        isPresented.toggle()
                    }
                    .popover(isPresented: $isPresented) {
                        ZStack(alignment: .topTrailing) {
                            Text("1")
                        }
                        .frame(width: 100, height: 100)
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
                        .onTapGesture {
                            isPresented.toggle()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
   Test()
}
