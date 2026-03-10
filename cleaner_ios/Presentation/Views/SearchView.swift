import SwiftUI
import Photos


struct SearchView: View {
    @Environment(\.mediaLibrary) var mediaLibrary

    @State private var searchText: String = ""
    @State private var searchResultsPhotos: [PhotoModel] = []
    @State private var searchResultsVideos: [VideoModel] = []
    @State private var navigationPath = NavigationPath()
    @State private var selectedTab = 0
    @State private var selectedItem: MediaItem?
    
    private var tabs = ["Фотографии", "Видео"]

    @Namespace private var navigationTransitionNamespace
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .top) {
                switch selectedTab {
                case 0:
                    if !searchResultsPhotos.isEmpty {
                        ScrollView {
                            MediaGrid(
                                items: searchResultsPhotos.map { .photo($0) },
                                selectedItem: $selectedItem,
                                namespace: navigationTransitionNamespace
                            )
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
                            MediaGrid(
                                items: searchResultsVideos.map { .video($0) },
                                selectedItem: $selectedItem,
                                namespace: navigationTransitionNamespace
                            )
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
            .fullScreenCover(item: $selectedItem) { item in
                let items: [MediaItem] = switch item {
                case .photo: searchResultsPhotos.map { .photo($0) }
                case .video: searchResultsVideos.map { .video($0) }
                }
                MediaDetailView(items: items, currentItem: item, namespace: navigationTransitionNamespace)
            }
            .searchable(text: $searchText, prompt: "Поиск фотографий и видео")
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .toolbar(.hidden, for: .navigationBar)
            .onSubmit(of: .search) {
                searchMedia()
            }
            .overlay(alignment: .top) {
                VStack {
                    PickerHeader(selectedTab: $selectedTab, tabs: tabs)
                        .padding(.top)
                }
            }
        }
    }
    
    private func searchMedia() {
        Task {
            let result = await mediaLibrary?.search(query: searchText)
            guard case .success(let results) = result else {
                await MainActor.run {
                    searchResultsPhotos = []
                    searchResultsVideos = []
                }
                return
            }

            let photos = results.compactMap { result -> PhotoModel? in
                guard case .photo(let photo) = result.item else { return nil }
                return photo
            }
            let videos = results.compactMap { result -> VideoModel? in
                guard case .video(let video) = result.item else { return nil }
                return video
            }

            await MainActor.run {
                searchResultsPhotos = photos
                searchResultsVideos = videos
            }
        }
    }

}
