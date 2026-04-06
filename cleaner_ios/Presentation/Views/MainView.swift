import SwiftUI

struct MainView: View {
    @Environment(\.appRouter) private var appRouter

    private static let tabAccent = Color(red: 69 / 255, green: 36 / 255, blue: 1)

    var body: some View {
        @Bindable var appRouter = appRouter

        NavigationStack(path: $appRouter.path) {
            TabView {
                Tab {
                    MainScreen()
                } label: {
                    Label("Main", image: "menu.main")
                }

                Tab {
                    VideosView()
                } label: {
                    Label("Compress", image: "menu.compress")
                }

                Tab {
                    SettingsView()
                } label: {
                    Label("Settings", image: "menu.gear")
                }

                Tab(role: .search) {
                    SearchView()
                } label: {
                    Label("Search", systemImage: "magnifyingglass")
                }
            }
            .accentColor(Self.tabAccent)
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .smartCleanup:
                    SmartCleanupSelector()
                }
            }
        }
    }
}

#Preview {
    MainView()
        .environment(\.appRouter,    AppRouter())
        .environment(\.photoLibrary, nil)
        .environment(\.videoLibrary, nil)
        .environment(\.mediaLibrary, nil)
        .environment(\.settings,     nil)
}

