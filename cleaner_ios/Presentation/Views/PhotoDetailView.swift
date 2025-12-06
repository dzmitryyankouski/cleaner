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
        isProcessing = true
        
        Task {
            guard let photo = selectedItem else { return }

            await photoLibrary?.delete(photo: photo)
            await MainActor.run {
                self.photos.removeAll { $0.id == photo.id }
                isProcessing = false

                if photos.count <= 1 {
                    dismiss()
                }
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
