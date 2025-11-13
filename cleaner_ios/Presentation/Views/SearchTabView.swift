import SwiftUI
import Photos

// MARK: - Search Tab View

struct SearchTabView: View {
    
    // MARK: - Properties
    
    @EnvironmentObject var viewModel: PhotoViewModel
    @State private var searchText: String = ""
    @State private var searchResults: [Photo] = []
    @State private var isSearching = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if viewModel.indexing {
                    indexingView
                } else {
                    resultsView
                }
            }
        }
        .searchable(text: $searchText)
    }
    
    // MARK: - Indexing View
    
    private var indexingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Индексация фотографий...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Обработано: \(viewModel.indexed) из \(viewModel.total)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    // MARK: - Search Input View
    
    private var searchInputView: some View {
        VStack(spacing: 16) {
            TextField("Введите текст для поиска", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button(action: performSearch) {
                HStack {
                    if isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    }
                    Text(isSearching ? "Поиск..." : "Поиск")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(searchButtonColor)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(!canSearch)
        }
    }
    
    // MARK: - Results View
    
    @ViewBuilder
    private var resultsView: some View {
        if !searchResults.isEmpty {
            searchResultsView
        } else if !viewModel.photos.isEmpty {
            allPhotosView
        } else {
            EmptyStateView(
                icon: "photo",
                title: "Нет фотографий",
                message: "Фотографии появятся после индексации"
            )
        }
    }
    
    // MARK: - Search Results View
    
    private var searchResultsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Результаты поиска (\(searchResults.count)):")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text("По запросу: \"\(searchText)\"")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Очистить") {
                    clearSearch()
                }
                .font(.caption)
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            .padding(.horizontal)
            
            photoGridView(photos: searchResults)
        }
    }
    
    // MARK: - All Photos View
    
    private var allPhotosView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Все фотографии (\(viewModel.photos.count)):")
                .font(.headline)
                .padding(.horizontal)
            
            photoGridView(photos: viewModel.photos)
        }
    }
    
    // MARK: - Photo Grid View
    
    private func photoGridView(photos: [Photo]) -> some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100), spacing: 10)
            ], spacing: 10) {
                ForEach(photos) { photo in
                    SearchPhotoThumbnail(photo: photo)
                        .frame(width: 100, height: 100)
                        .cornerRadius(8)
                        .shadow(radius: 2)
                }
            }
            .padding(.horizontal)
            .padding(.vertical)
        }
    }
    
    // MARK: - Computed Properties
    
    private var canSearch: Bool {
        !viewModel.indexing && !isSearching && !searchText.isEmpty
    }
    
    private var searchButtonColor: Color {
        canSearch ? .blue : .gray
    }
    
    // MARK: - Private Methods
    
    private func performSearch() {
        guard canSearch else { return }
        
        isSearching = true
        Task {
            searchResults = await viewModel.search(text: searchText)
            await MainActor.run {
                isSearching = false
            }
        }
    }
    
    private func clearSearch() {
        searchResults = []
        searchText = ""
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

// MARK: - Search Photo Thumbnail

struct SearchPhotoThumbnail: View {
    let photo: Photo
    @State private var image: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Group {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                                    .font(.title2)
                            }
                        }
                    )
            }
        }
        .onAppear {
            loadThumbnail()
        }
        .onDisappear {
            image = nil
        }
    }
    
    private func loadThumbnail() {
        guard !isLoading && image == nil else { return }
        
        isLoading = true
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .opportunistic
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = false
        
        PHImageManager.default().requestImage(
            for: photo.asset,
            targetSize: CGSize(width: 200, height: 200),
            contentMode: .aspectFill,
            options: options
        ) { result, _ in
            DispatchQueue.main.async {
                self.isLoading = false
                self.image = result
            }
        }
    }
}

