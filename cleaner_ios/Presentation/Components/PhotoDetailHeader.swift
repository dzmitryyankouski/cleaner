import Photos
import SwiftUI

struct PhotoDetailHeader: View {
    // MARK: - Environment
    @Environment(\.photoLibrary) var photoLibrary
    @Environment(\.dismiss) var dismiss
    
    // MARK: - Bindings
    @Binding var photos: [PhotoModel]
    @Binding var selectedItem: PhotoModel?
    
    // MARK: - Private State
    @State private var isProcessing = false
    @State private var showRemoveLiveConfirmation = false

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
                        guard let photo = selectedItem else { return }
                        handleDelete(photo: photo)
                    }
                ) {
                    Label("Remove", systemImage: "trash")
                }
                .disabled(selectedItem == nil || isProcessing)

                Button(action: {
                    showRemoveLiveConfirmation = true
                }) {
                    Label("Remove Live", systemImage: "livephoto")
                }
                .disabled(
                    selectedItem == nil || isProcessing || selectedItem?.isLivePhoto != true)

                Button(action: {
                    guard let photo = selectedItem else { return }
                    handleCompress(photo: photo)
                }) {
                    Label("Compress", systemImage: "arrow.down.to.line")
                }
                .disabled(selectedItem == nil || isProcessing || selectedItem?.isCompressed == true)
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
                    guard let photo = selectedItem else { return }
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
            let index = photos.firstIndex { $0.id == photo.id }
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
                        photos.remove(at: index)

                        if photos.isEmpty {
                            dismiss()
                        } else if index < photos.count {
                            selectedItem = photos[index]
                        } else if index > 0 {
                            selectedItem = photos[index - 1]
                        } else {
                            selectedItem = photos.first
                        }
                    }
                }
            case .failure(let error):
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

