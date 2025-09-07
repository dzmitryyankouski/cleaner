import SwiftUI
import Photos

struct PhotosView: View {
    @StateObject private var viewModel = PhotosViewModel()

    var body: some View {
        VStack {
            if viewModel.isIndexing {
                VStack(spacing: 20) {
                    Text("Индексация фотографий")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Обработано: \(viewModel.processedPhotosCount) из \(viewModel.photos.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: Double(viewModel.processedPhotosCount), total: Double(viewModel.photos.count))
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 200)
                    
                    Text("Поиск похожих изображений...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            // Отображение групп картинок после завершения индексации
            else if !viewModel.groups.isEmpty {
                let filteredGroups = viewModel.groups.filter { $0.count > 1 }
                
                if !filteredGroups.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {      
                        ScrollView {
                            LazyVStack(spacing: 20) {
                                ForEach(Array(filteredGroups.enumerated()), id: \.offset) { groupIndex, group in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Группа \(groupIndex + 1) (\(group.count) фото)")
                                            .font(.headline)
                                            .padding(.horizontal)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 12) {
                                                ForEach(group, id: \.self) { imageIndex in
                                                    if imageIndex < viewModel.photos.count {
                                                        AsyncImage(asset: viewModel.photos[imageIndex], size: CGSize(width: 120, height: 120)) { image in
                                                            image
                                                                .resizable()
                                                                .aspectRatio(contentMode: .fill)
                                                                .frame(width: 120, height: 120)
                                                                .clipped()
                                                                .cornerRadius(8)
                                                                .shadow(radius: 4)
                                                        } placeholder: {
                                                            Rectangle()
                                                                .fill(Color.gray.opacity(0.3))
                                                                .frame(width: 120, height: 120)
                                                                .cornerRadius(8)
                                                        }
                                                    }
                                                }
                                            }
                                            .padding(.horizontal)
                                        }
                                    }
                                }
                            }
                            .padding(.top)
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("Похожие фотографии не найдены")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Попробуйте выбрать другие изображения")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            // Состояние загрузки фотографий
            else if viewModel.photos.isEmpty && !viewModel.isIndexing {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("Загрузка фотографий из галереи...")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Пожалуйста, подождите")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
    }
}

struct AsyncImage<Content: View, Placeholder: View>: View {
    let asset: PHAsset
    let size: CGSize
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var image: UIImage?
    @State private var isLoading = true
    
    init(asset: PHAsset, size: CGSize, @ViewBuilder content: @escaping (Image) -> Content, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.asset = asset
        self.size = size
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else {
                placeholder()
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .opportunistic
        options.resizeMode = .exact
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
        ) { result, _ in
            DispatchQueue.main.async {
                self.image = result
                self.isLoading = false
            }
        }
    }
}

#Preview {
    PhotosView()
}