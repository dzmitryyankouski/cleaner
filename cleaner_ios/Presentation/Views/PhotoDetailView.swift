import SwiftUI
import Photos

struct PhotoDetailView: View {
    @State var photos: [PhotoModel]

    let currentItem: PhotoModel
    var namespace: Namespace.ID

    @Environment(\.photoLibrary) var photoLibrary
    @Environment(\.dismiss) var dismiss
    
    @State private var assets: [String: PHAsset] = [:]
    @State private var showDeleteConfirmation = false
    @State private var showRemoveLiveConfirmation = false
    @State private var isProcessing = false
    @State private var selectedItem: PhotoModel? = nil
    @State private var itemToDelete: PhotoModel? = nil

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedItem) {
                ForEach(photos, id: \.id) { photo in
                    GeometryReader { geometry in
                        Photo(photo: photo, quality: .high, contentMode: .fit)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    }
                    .id(photo.id)
                    .tag(photo)
                    .ignoresSafeArea()
                }
            }
            .onAppear {
                selectedItem = currentItem
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
        }
        .overlay(
            VStack {
                Spacer()
                PhotoThumbnailIndicator(photos: photos, selectedItem: $selectedItem)
            }
        )
        .navigationTitle(selectedItem?.id ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .navigationTransition(.zoom(sourceID: selectedItem?.id ?? currentItem.id, in: namespace))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive, action: {
                        itemToDelete = selectedItem
                        showDeleteConfirmation = true
                    }) {
                        Label("Remove", systemImage: "trash")
                    }
                    .disabled(selectedItem == nil || isProcessing)
                    
                    Button(action: {
                        showRemoveLiveConfirmation = true
                    }) {
                        Label("Remove Live", systemImage: "livephoto")
                    }
                    .disabled(selectedItem == nil || isProcessing || selectedItem?.isLivePhoto != true)
                    
                    Button(action: {
                        handleCompress()
                    }) {
                        Label("Compress", systemImage: "arrow.down.to.line")
                    }
                    .disabled(selectedItem == nil || isProcessing)
                } label: {
                    Image(systemName: "ellipsis")
                }
                .disabled(isProcessing)
                .confirmationDialog("Удалить фотографию?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                    Button("Удалить", role: .destructive) {
                        print("выбранный элемент: \(itemToDelete?.id)")
                        handleDelete()
                    }
                } message: {
                    Text("Это действие нельзя отменить")
                }
                .confirmationDialog("Удалить Live Photo?", isPresented: $showRemoveLiveConfirmation, titleVisibility: .visible) {
                    Button("Удалить", role: .destructive) {
                        handleRemoveLive()
                    }
                } message: {
                    Text("Будет удалена только Live Photo часть, само фото останется")
                }
            }
        }
    }
    
    private func handleDelete() {
        guard let photoToDelete = itemToDelete else { return }
        isProcessing = true

        Task {
            let index = photos.firstIndex { $0.id == photoToDelete.id }

            await photoLibrary?.delete(photo: photoToDelete)
            await MainActor.run {
                if let index = index {
                    photos.remove(at: index)

                    if photos.count <= 1 {
                        isProcessing = false
                        itemToDelete = nil
                        dismiss()
                    } else {
                        selectedItem = photos[index]
                    }
                }
                
                isProcessing = false
            }
        }
    }
    
    private func handleRemoveLive() {
        guard let photo = selectedItem else { return }
        isProcessing = true
        
        Task {
            await photoLibrary?.removeLive(photo: photo)
            await MainActor.run {
                isProcessing = false
            }
        }
    }
    
    private func handleCompress() {
        guard let photo = selectedItem else { return }
        isProcessing = true
        
        Task {
            await photoLibrary?.compress(photo: photo)
            await MainActor.run {
                isProcessing = false
            }
        }
    }
}
