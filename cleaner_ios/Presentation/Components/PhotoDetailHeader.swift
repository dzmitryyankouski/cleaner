import Photos
import SwiftUI

struct PhotoDetailHeader: View {
    // MARK: - Environment
    @Environment(\.photoLibrary) var photoLibrary
    @Environment(\.dismiss) var dismiss
    
    // MARK: - Bindings
    @Binding var items: [MediaItem]
    @Binding var selectedItem: MediaItem?
    
    // MARK: - Private State
    @State private var isProcessing = false
    @State private var showRemoveLiveConfirmation = false

    private var selectedPhoto: PhotoModel? {
        guard case .photo(let photo) = selectedItem else { return nil }
        return photo
    }

    var body: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .frame(width: 45, height: 45)
                    .font(.system(size: 18))
                    .foregroundColor(.black)
                    .glassEffect()

            }

            Spacer()

            Menu {
                Button(
                    role: .destructive,
                    action: {
                        guard let photo = selectedPhoto else { return }
                        handleDelete(photo: photo)
                    }
                ) {
                    Label("Remove", systemImage: "trash")
                }
                .disabled(selectedPhoto == nil || isProcessing)

                Button(action: {
                    showRemoveLiveConfirmation = true
                }) {
                    Label("Remove Live", systemImage: "livephoto")
                }
                .disabled(
                    selectedPhoto == nil || isProcessing || selectedPhoto?.isLivePhoto != true)

                Button(action: {
                    guard let photo = selectedPhoto else { return }
                    handleCompress(photo: photo)
                }) {
                    Label("Compress", systemImage: "arrow.down.to.line")
                }
                .disabled(selectedPhoto == nil || isProcessing || selectedPhoto?.isCompressed == true)
            } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 45, height: 45)
                    .font(.system(size: 18))
                    .foregroundColor(.black)
                    .glassEffect()
            }
            .disabled(isProcessing)
            .confirmationDialog(
                "Удалить Live Photo?", isPresented: $showRemoveLiveConfirmation,
                titleVisibility: .visible
            ) {
                Button("Удалить", role: .destructive) {
                    guard let photo = selectedPhoto else { return }
                    handleRemoveLive(photo: photo)
                }
            } message: {
                Text("Будет удалена только Live Photo часть, само фото останется")
            }
        }
        .padding(.horizontal, 10)
    }

    // MARK: - Private Methods
    private func handleDelete(photo: PhotoModel) {
        isProcessing = true

        Task {
            let index = items.firstIndex { $0.id == photo.id }
            guard let result = await photoLibrary?.delete(photos: [photo]) else {
                await MainActor.run {
                    isProcessing = false
                }
                return
            }

            switch result {
            case .success:
                await MainActor.run {
                    if let index = index {
                        isProcessing = false
                        items.remove(at: index)

                        if items.isEmpty {
                            dismiss()
                        } else if index < items.count {
                            selectedItem = items[index]
                        } else if index > 0 {
                            selectedItem = items[index - 1]
                        } else {
                            selectedItem = items.first
                        }
                    }
                }
            case .failure:
                await MainActor.run {
                    isProcessing = false
                }
            }
        }
    }

    private func handleRemoveLive(photo: PhotoModel) {
        isProcessing = true

        Task {
            guard let result = await photoLibrary?.removeLive(photos: [photo]) else {
                await MainActor.run {
                    isProcessing = false
                }
                return
            }

            guard case .success = result else {
                await MainActor.run {
                    isProcessing = false
                }
                return
            }

            await MainActor.run {
                isProcessing = false
            }
        }
    }

    private func handleCompress(photo: PhotoModel) {
        isProcessing = true

        Task {
            guard let result = await photoLibrary?.compress(photos: [photo]) else {
                await MainActor.run {
                    isProcessing = false
                }
                return
            }

            guard case .success = result else {
                await MainActor.run {
                    isProcessing = false
                }
                return
            }

            await MainActor.run {
                isProcessing = false
            }
        }
    }
}

