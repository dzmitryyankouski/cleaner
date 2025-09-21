import SwiftUI
import Photos

struct PhotosView: View {
    @ObservedObject var photoService = PhotoService.shared
    @State private var selectedTab = 0
    
    private let tabs = ["Похожие", "Дубликаты", "Скриншоты", "Серии"]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Статистика или прогресс индексации
                VStack(spacing: 8) {
                    if photoService.indexing {
                        // Прогресс индексации
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Индексация фотографий")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(photoService.indexed) из \(photoService.total)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Прогресс")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                ProgressView(value: Double(photoService.indexed), total: Double(photoService.total))
                                    .progressViewStyle(LinearProgressViewStyle())
                                    .frame(width: 80)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    } else if !photoService.photos.isEmpty {
                        // Статистика после завершения индексации
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Всего фотографий")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(photoService.getTotalPhotosCount())")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Общий размер")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(photoService.formatFileSize(photoService.getTotalFileSize()))
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                // Сегментированный контрол для табов
                Picker("Табы", selection: $selectedTab) {
                    ForEach(0..<tabs.count, id: \.self) { index in
                        Text(tabs[index]).tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Контент в зависимости от выбранного таба
                Group {
                    switch selectedTab {
                    case 0:
                        SimilarPhotosTab()
                    case 1:
                        DuplicatesTab()
                    case 2:
                        ScreenshotsTab()
                    case 3:
                        SeriesTab()
                    default:
                        SimilarPhotosTab()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Фотографии")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Обновить") {
                        Task {
                            await photoService.refreshPhotos()
                        }
                    }
                    .disabled(photoService.indexing)
                }
            }
        }
    }
}

// Таб с похожими фотографиями
struct SimilarPhotosTab: View {
    @ObservedObject var photoService = PhotoService.shared
    
    var body: some View {
        VStack {
            if photoService.indexing {
                VStack(spacing: 20) {
                    Text("Поиск похожих изображений...")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Анализ фотографий и создание групп")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            // Отображение групп картинок после завершения индексации
            else if !photoService.groups.isEmpty {
                let filteredGroups = photoService.groups.filter { $0.count > 1 }
                
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
                                                ForEach(group, id: \.asset.localIdentifier) { photo in
                                                    AsyncImage(asset: photo.asset, size: CGSize(width: 120, height: 120)) { image in
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
            else if photoService.photos.isEmpty {
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
            
            Spacer()
        }
    }
}

// Таб с дубликатами
struct DuplicatesTab: View {
    @ObservedObject var photoService = PhotoService.shared
    
    var body: some View {
        VStack {
            if photoService.indexing {
                VStack(spacing: 20) {
                    Text("Поиск дубликатов...")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Анализ фотографий на наличие точных копий")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            // Отображение дубликатов после завершения индексации
            else if !photoService.photos.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text("Дубликаты")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Функция в разработке")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            // Состояние загрузки фотографий
            else if photoService.photos.isEmpty {
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
            
            Spacer()
        }
    }
}

// Таб со скриншотами
struct ScreenshotsTab: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("Скриншоты")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Функция в разработке")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        
        Spacer()
    }
}

// Таб с сериями
struct SeriesTab: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.stack")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("Серии")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Функция в разработке")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        
        Spacer()
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