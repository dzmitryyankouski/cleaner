import SwiftUI

struct MainView: View {
    @Environment(\.appRouter) private var appRouter

    var body: some View {
        @Bindable var appRouter = appRouter

        NavigationStack(path: $appRouter.path) {
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
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .smartCleanup:
                    SmartCleanupSelector()
                }
            }
        }
    }
}
