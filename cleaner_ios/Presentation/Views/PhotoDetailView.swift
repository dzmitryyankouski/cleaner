import SwiftUI
import Photos

struct PhotoDetailView: View {
    @State var photos: [PhotoModel]

    let currentPhotoId: String
    var namespace: Namespace.ID

    @Environment(\.photoLibrary) var photoLibrary
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedPhotoId: String? = nil
    @State private var assets: [String: PHAsset] = [:]
    @State private var showDeleteConfirmation = false
    @State private var showRemoveLiveConfirmation = false
    @State private var isProcessing = false

    private var currentPhoto: PhotoModel? {
        guard let selectedPhotoId = selectedPhotoId else { return nil }
        return photos.first { $0.id == selectedPhotoId }
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedPhotoId) {
                ForEach(photos, id: \.id) { photo in
                    GeometryReader { geometry in
                        Photo(photo: photo, quality: .high, contentMode: .fit)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    }
                    .id(photo.id)
                    .tag(photo.id)
                    .ignoresSafeArea()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onAppear {
                selectedPhotoId = currentPhotoId
            }
            .ignoresSafeArea()
        }
        .overlay(
            VStack {
                Spacer()
                PhotoThumbnailIndicator(photos: photos, selectedPhotoId: $selectedPhotoId)
            }
        )
        .navigationTitle("Группа (\(photos.count))")
        .navigationBarTitleDisplayMode(.inline)
        .navigationTransition(.zoom(sourceID: selectedPhotoId ?? currentPhotoId, in: namespace))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive, action: {
                        showDeleteConfirmation = true
                    }) {
                        Label("Remove", systemImage: "trash")
                    }
                    .disabled(currentPhoto == nil || isProcessing)
                    
                    Button(action: {
                        showRemoveLiveConfirmation = true
                    }) {
                        Label("Remove Live", systemImage: "livephoto")
                    }
                    .disabled(currentPhoto == nil || isProcessing || currentPhoto?.isLivePhoto != true)
                    
                    Button(action: {
                        handleCompress()
                    }) {
                        Label("Compress", systemImage: "arrow.down.to.line")
                    }
                    .disabled(currentPhoto == nil || isProcessing)
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
        guard let photo = currentPhoto else { return }
        isProcessing = true
        
        Task {
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
        guard let photo = currentPhoto else { return }
        isProcessing = true
        
        Task {
            await photoLibrary?.removeLive(photo: photo)
            await MainActor.run {
                isProcessing = false
            }
        }
    }
    
    private func handleCompress() {
        guard let photo = currentPhoto else { return }
        isProcessing = true
        
        Task {
            await photoLibrary?.compress(photo: photo)
            await MainActor.run {
                isProcessing = false
            }
        }
    }
}
