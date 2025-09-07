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

            PhotosPicker(selection: $selectedItems, maxSelectionCount: 20, matching: .images) {
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
        }
    }
}

#Preview {
    PhotosView()
}