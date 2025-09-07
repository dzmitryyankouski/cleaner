import SwiftUI
import Photos
import PhotosUI

struct SearchView: View {
    @State private var searchText: String = ""
    @State private var resultText: String = ""

    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        VStack(spacing: 20) {
            TextField("Введите текст для поиска", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button(action: {
                // Здесь может быть логика поиска
                resultText = "Вы ввели: \(searchText)"
            }) {
                Text("Поиск")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            if !resultText.isEmpty {
                Text(resultText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            }

            Spacer()

        // Выводим список всех фотографий из viewModel.photos
        if !viewModel.photos.isEmpty {
            Text("Все фотографии (\(viewModel.photos.count)):")
                .font(.headline)
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
