import SwiftUI
import Photos


struct SearchTabView: View {
    @Environment(\.photoLibrary) var photoLibrary

    @State private var searchText: String = ""
    @State private var searchResults: [PhotoModel] = []
    @State private var navigationPath = NavigationPath()
    @Binding var selectedMenu: Int

    @Namespace private var navigationTransitionNamespace
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                if !searchResults.isEmpty  {
                    PhotoGridView(photos: searchResults, navigationPath: $navigationPath, namespace: navigationTransitionNamespace)
                }
            }
            .searchable(text: $searchText, prompt: title())
            .onSubmit(of: .search) {
                searchPhotos()
            }
            .navigationTitle(title())
            .navigationDestination(for: PhotoGroupNavigationItem.self) { item in
                PhotoDetailView(photos: item.photos, currentPhotoId: item.currentPhotoId, namespace: navigationTransitionNamespace)
            }
        }
    }

    private func title() -> String {
        switch selectedMenu {
        case 0:
            return "Поиск Фотографий"
        case 1:
            return "Поиск Видео"
        default:
            return "Поиск"
        }
    }
    
    private func searchPhotos() {
        Task {
            let result = await photoLibrary?.search(query: searchText)
            switch result {
            case .success(let results):
                await MainActor.run {
                    searchResults = results.map { $0.item }
                }
            case .failure(let error):
                print("❌ Ошибка поиска: \(error)")
                await MainActor.run {
                    searchResults = []
                }
            case .none:
                await MainActor.run {
                    searchResults = []
                }
            }
        }
    }
}
