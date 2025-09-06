//
//  ContentView.swift
//  cleaner_ios
//
//  Created by Dmitriy Yankovskiy on 06/09/2025.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @StateObject private var embeddingService = ImageEmbeddingService()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Отображение выбранного изображения
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .cornerRadius(10)
                } else {
                    Image(systemName: "photo")
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                        .frame(height: 200)
                }
                
                Text(selectedImage != nil ? "Изображение выбрано" : "Выберите изображение")
                    .font(.headline)
                
                // Кнопка для выбора изображения
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("Выбрать из галереи", systemImage: "photo.on.rectangle")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
                // Кнопка для генерации эмбединга
                if selectedImage != nil {
                    Button(action: {
                        if let image = selectedImage {
                            embeddingService.generateEmbedding(from: image)
                        }
                    }) {
                        HStack {
                            if embeddingService.isProcessing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(embeddingService.isProcessing ? "Генерация эмбединга..." : "Сгенерировать эмбединг")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(embeddingService.isProcessing ? Color.gray : Color.green)
                        .cornerRadius(10)
                    }
                    .disabled(embeddingService.isProcessing)
                }
                
                // Отображение ошибки
                if let errorMessage = embeddingService.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Отображение статистики эмбединга
                if let _ = embeddingService.embedding {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Статистика эмбединга")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(embeddingService.getEmbeddingStatistics())
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                // Отображение эмбединга (первые несколько значений)
                if let _ = embeddingService.embedding {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Эмбединг (первые 10 значений)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        let embeddingPreview = Array(embeddingService.embedding!.prefix(10))
                        let previewText = embeddingPreview.map { String(format: "%.4f", $0) }.joined(separator: ", ")
                        
                        Text(previewText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        
                        if embeddingService.embedding!.count > 10 {
                            Text("... и еще \(embeddingService.embedding!.count - 10) значений")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    selectedImage = UIImage(data: data)
                    // Сбрасываем предыдущий эмбединг при выборе нового изображения
                    embeddingService.embedding = nil
                    embeddingService.errorMessage = nil
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
