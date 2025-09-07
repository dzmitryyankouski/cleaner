import SwiftUI
import PhotosUI

struct PhotosView: View {
    @StateObject private var viewModel = PhotosViewModel()
    @State private var selectedItems: [PhotosPickerItem] = []

    var body: some View {
        VStack {
            Text("Photo Comparison")
                .font(.largeTitle)
                .padding(.top)

            PhotosPicker(selection: $selectedItems, maxSelectionCount: 60, matching: .images) {
                Label("Select Images", systemImage: "photo.on.rectangle.angled")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }.onChange(of: selectedItems) { _, newItems in
                Task {
                    await viewModel.onSelectImages(items: newItems)
                }
            }

            // Отображение групп картинок
            if !viewModel.groups.isEmpty {
                let filteredGroups = viewModel.groups.filter { $0.count > 1 }
                
                if !filteredGroups.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(Array(filteredGroups.enumerated()), id: \.offset) { groupIndex, group in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Group \(groupIndex + 1)")
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(group, id: \.self) { imageIndex in
                                                if imageIndex < viewModel.selectedImages.count {
                                                    Image(uiImage: viewModel.selectedImages[imageIndex])
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 120, height: 120)
                                                        .clipped()
                                                        .cornerRadius(8)
                                                        .shadow(radius: 4)
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
                } else {
                    Text("Нет групп с несколькими изображениями")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                }
            } else if !viewModel.selectedImages.isEmpty {
                Text("Обработка изображений...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
}

#Preview {
    PhotosView()
}