import SwiftUI
import Photos


struct SearchTabView: View {
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
            ScrollView {
                Section {
                    switch selectedTab {
                    case 0:
                        PhotoGridView(photos: searchResultsPhotos, navigationPath: $navigationPath, namespace: navigationTransitionNamespace)
                    case 1:
                        VideoGridView(videos: searchResultsVideos, navigationPath: $navigationPath, namespace: navigationTransitionNamespace)
                    default:
                        PhotoGridView(photos: searchResultsPhotos, navigationPath: $navigationPath, namespace: navigationTransitionNamespace)
                    }
                } header: {
                    PickerHeader(selectedTab: $selectedTab, tabs: tabs)
                }
            }
            .searchable(text: $searchText, prompt: "Поиск фотографий и видео")
            .onSubmit(of: .search) {
                searchPhotos()
                searchVideos()
            }
            .navigationTitle("Поиск")
            .navigationDestination(for: PhotoGroupNavigationItem.self) { item in
                PhotoDetailView(photos: item.photos, currentPhotoId: item.currentPhotoId, namespace: navigationTransitionNamespace)
            }
            .navigationDestination(for: VideoGroupNavigationItem.self) { item in
                VideoDetailView(videos: item.videos, currentVideoId: item.currentVideoId, namespace: navigationTransitionNamespace)
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
