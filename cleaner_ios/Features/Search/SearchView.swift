import SwiftUI
import Photos
import PhotosUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        VStack(spacing: 20) {
            TextField("Введите текст для поиска", text: $viewModel.searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button(action: {
                Task {
                    await viewModel.searchImages()
                }
            }) {
                HStack {
                    if viewModel.isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    }
                    Text(viewModel.isSearching ? "Поиск..." : "Поиск")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(viewModel.isIndexing || viewModel.isSearching)

            Spacer()

        // Индикатор прогресса индексации
        if viewModel.isIndexing {
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Индексация фотографий...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Обработано: \(viewModel.processedPhotosCount) из \(viewModel.photos.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        
        // Отображаем результаты поиска или все фотографии
        if !viewModel.searchResults.isEmpty {
            // Показываем результаты поиска
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Результаты поиска (\(viewModel.searchResults.count)):")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text("По запросу: \"\(viewModel.searchText)\"")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Очистить") {
                        viewModel.searchResults = []
                        viewModel.searchResultsWithScores = []
                        viewModel.searchText = ""
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100), spacing: 10)
                ], spacing: 10) {
                    ForEach(Array(viewModel.searchResultsWithScores.enumerated()), id: \.element.0.localIdentifier) { index, result in
                        VStack(spacing: 4) {
                            PhotoThumbnailView(asset: result.0)
                                .frame(width: 100, height: 100)
                                .cornerRadius(8)
                                .shadow(radius: 2)
                            
                            // Показываем оценку сходства
                            Text("\(String(format: "%.1f", result.1 * 100))%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical)
            }
        } else if !viewModel.photos.isEmpty {
            // Показываем все фотографии, если нет результатов поиска
            VStack(alignment: .leading, spacing: 8) {
                Text("Все фотографии (\(viewModel.photos.count)):")
                    .font(.headline)
                
                if viewModel.processedPhotosCount > 0 {
                    Text("С эмбедингами: \(viewModel.processedPhotosCount)")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal)
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100), spacing: 10)
                ], spacing: 10) {
                    ForEach(viewModel.photos, id: \.localIdentifier) { asset in
                        PhotoThumbnailView(asset: asset)
                            .frame(width: 100, height: 100)
                            .cornerRadius(8)
                            .shadow(radius: 2)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical)
            }
        } else {
            Text("Нет фотографий")
                .foregroundColor(.secondary)
                .padding()
        }
        }
        .padding(.top, 40)
    }
}

struct PhotoThumbnailView: View {
    let asset: PHAsset
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
            // Освобождаем память при исчезновении view
            image = nil
        }
    }
    
    private func loadThumbnail() {
        // Проверяем, не загружается ли уже
        guard !isLoading && image == nil else { return }
        
        isLoading = true
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        
        // Оптимизированные настройки
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .opportunistic // Сначала быстрое изображение низкого качества
        requestOptions.resizeMode = .exact
        requestOptions.isNetworkAccessAllowed = false // Только локальные изображения
        
        imageManager.requestImage(
            for: asset,
            targetSize: CGSize(width: 200, height: 200),
            contentMode: .aspectFill,
            options: requestOptions
        ) { result, info in
            DispatchQueue.main.async {
                self.isLoading = false
                self.image = result
            }
        }
    }
}

#Preview {
    SearchView()
}
