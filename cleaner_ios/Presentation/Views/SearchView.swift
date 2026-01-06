import SwiftUI
import Photos


struct SearchView: View {
    @Environment(\.photoLibrary) var photoLibrary
    @Environment(\.videoLibrary) var videoLibrary

    @State private var searchText: String = ""
    @State private var searchResultsPhotos: [PhotoModel] = []
    @State private var searchResultsVideos: [VideoModel] = []
    @State private var navigationPath = NavigationPath()
    @State private var selectedTab = 0
    
    private var tabs = ["Фотографии", "Видео"]

    @Namespace private var navigationTransitionNamespace
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .top) {
                switch selectedTab {
                case 0:
                    if !searchResultsPhotos.isEmpty {
                        ScrollView {
                            PhotoGrid(photos: searchResultsPhotos, namespace: navigationTransitionNamespace)
                        }
                    } else {
                        EmptyState(
                            icon: "photo",
                            title: "Фотографии не найдены",
                            message: "В вашей галерее нет фотографий"
                        )
                    }
                case 1:
                    if !searchResultsVideos.isEmpty {
                        ScrollView {
                            VideoGrid(videos: searchResultsVideos, namespace: navigationTransitionNamespace)
                        }
                    } else {
                        EmptyState(
                            icon: "video",
                            title: "Видео не найдены",
                            message: "В вашей галерее нет видео"
                        )
                    }
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .searchable(text: $searchText, prompt: "Поиск фотографий и видео")
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .toolbar(.hidden, for: .navigationBar)
            .onSubmit(of: .search) {
                searchPhotos()
                searchVideos()
            }
            .overlay(alignment: .top) {
                VStack {
                    PickerHeader(selectedTab: $selectedTab, tabs: tabs)
                        .padding(.top)
                }
            }
        }
    }
    
    private func searchPhotos() {
        Task {
            let result = await photoLibrary?.search(query: searchText)
            switch result {
            case .success(let results):
                await MainActor.run {
                    searchResultsPhotos = results.map { $0.item }
                }
            case .failure(let error):
                print("❌ Ошибка поиска: \(error)")
                await MainActor.run {
                    searchResultsPhotos = []
                }
            case .none:
                await MainActor.run {
                    searchResultsPhotos = []
                }
            }
        }
    }

    private func searchVideos() {
        Task {
            let result = await videoLibrary?.search(query: searchText)
            switch result {
            case .success(let results):
                await MainActor.run {
                    searchResultsVideos = results.map { $0.item }
                }
            case .failure(let error):
                print("❌ Ошибка поиска: \(error)")
                await MainActor.run {
                    searchResultsVideos = []
                }
            case .none:
                await MainActor.run {
                    searchResultsVideos = []
                }
            }
        }
    }
}
