import SwiftUI
import Photos
import PhotosUI

struct SearchView: View {
    @ObservedObject var photoService = PhotoService.shared
    
    @State private var searchText: String = ""
    @State private var searchResults: [Photo] = []
    @State private var isSearching = false

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            
            VStack(spacing: 20) {
                if photoService.indexing {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Индексация фотографий...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Обработано: \(photoService.indexed) из \(photoService.total)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    TextField("Введите текст для поиска", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    Button(action: {
                        Task {
                            await searchImages()
                        }
                    }) {
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
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .disabled(photoService.indexed < photoService.total || isSearching)
                    }

                Spacer()
                
                // Отображаем результаты поиска или все фотографии
                if !searchResults.isEmpty {
                    // Показываем результаты поиска
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
                                searchResults = []
                                searchText = ""
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
                            ForEach(searchResults, id: \.asset.localIdentifier) { photo in
                                PhotoThumbnailView(asset: photo.asset)
                                    .frame(width: 100, height: 100)
                                    .cornerRadius(8)
                                    .shadow(radius: 2)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical)
                    }
                } else if !photoService.photos.isEmpty {
                    // Показываем все фотографии, если нет результатов поиска
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Все фотографии (\(photoService.photos.count)):")
                            .font(.headline)
                        
                        if photoService.indexed > 0 {
                            Text("С эмбедингами: \(photoService.indexed)")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal)
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 100), spacing: 10)
                        ], spacing: 10) {
                            ForEach(photoService.photos, id: \.asset.localIdentifier) { photo in
                                PhotoThumbnailView(asset: photo.asset)
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
        }
        .navigationTitle("Поиск")
        .navigationBarTitleDisplayMode(.inline)
        .padding(.top, 40)
    }
    
    private func searchImages() async {
        guard !searchText.isEmpty else { return }
        
        print("🔍 Поиск изображений: \(searchText)")
        
        isSearching = true
        searchResults = await photoService.search(text: searchText)
        isSearching = false
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
