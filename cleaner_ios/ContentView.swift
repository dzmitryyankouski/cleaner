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
                        Text("Сгенерировать эмбединг")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    selectedImage = UIImage(data: data)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
