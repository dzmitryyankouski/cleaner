//
//  ContentView.swift
//  cleaner_ios
//
//  Created by Dmitriy Yankovskiy on 06/09/2025.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedImages: [UIImage] = []
    @State private var selectedItems: [PhotosPickerItem] = []
    @StateObject private var embeddingService = ImageEmbeddingService()
    @State private var similarities: [[Float]] = []
    @State private var isGeneratingEmbeddings = false
    @State private var isComparing = false
    @State private var selectedImage1Index: Int = 0
    @State private var selectedImage2Index: Int = 1
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Сравнение изображений")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Выбор множественных изображений
                VStack(spacing: 15) {
                    Text("Выберите изображения для сравнения")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    PhotosPicker(selection: $selectedItems, maxSelectionCount: 2, matching: .images) {
                        Label("Выбрать изображения (до 10)", systemImage: "photo.on.rectangle.angled")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    
                    if !selectedImages.isEmpty {
                        Text("Выбрано изображений: \(selectedImages.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Отображение выбранных изображений
                if !selectedImages.isEmpty {
                    VStack(spacing: 15) {
                        Text("Выбранные изображения")
                            .font(.headline)
                            .padding(.top)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                            ForEach(0..<selectedImages.count, id: \.self) { index in
                                VStack(spacing: 5) {
                                    Image(uiImage: selectedImages[index])
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 120)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(selectedImage1Index == index ? Color.blue : 
                                                       selectedImage2Index == index ? Color.green : Color.gray, lineWidth: 2)
                                        )
                                        .onTapGesture {
                                            selectImageForComparison(index: index)
                                        }
                                    
                                    Text("Изображение \(index + 1)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if embeddingService.embeddings.indices.contains(index) && !embeddingService.embeddings[index].isEmpty {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Кнопки управления
                if !selectedImages.isEmpty {
                    VStack(spacing: 15) {
                        // Генерация эмбеддингов для всех изображений
                        Button(action: {
                            generateAllEmbeddings()
                        }) {
                            HStack {
                                if isGeneratingEmbeddings {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                }
                                Text(isGeneratingEmbeddings ? "Генерируем эмбеддинги..." : "Сгенерировать эмбеддинги для всех")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(embeddingService.embeddings.count == selectedImages.count ? Color.gray : Color.green)
                            .cornerRadius(10)
                        }
                        .disabled(isGeneratingEmbeddings || embeddingService.embeddings.count == selectedImages.count)
                        
                        // Сравнение выбранных изображений
                        if embeddingService.embeddings.count >= 2 {
                            Button(action: {
                                compareSelectedImages()
                            }) {
                                HStack {
                                    if isComparing {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .foregroundColor(.white)
                                    }
                                    Text(isComparing ? "Сравниваем..." : "Сравнить выбранные изображения")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.purple)
                                .cornerRadius(10)
                            }
                            .disabled(isComparing)
                        }
                    }
                }
                
                // Результаты сравнения
                if !similarities.isEmpty {
                    VStack(spacing: 15) {
                        Text("Результаты сравнения")
                            .font(.headline)
                            .padding(.top)
                        
                        if similarities.count == 1 && similarities[0].count == 1 {
                            // Результат сравнения двух изображений
                            let similarity = similarities[0][0]
                            VStack(spacing: 10) {
                                Text("Сравнение изображений \(selectedImage1Index + 1) и \(selectedImage2Index + 1)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("Коэффициент сходства: \(String(format: "%.2f", similarity * 100))%")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(similarityColor(for: similarity))
                                
                                Text(similarityDescription(for: similarity))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        } else {
                            // Матрица сравнений всех изображений
                            Text("Матрица сходства всех изображений")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                VStack(spacing: 5) {
                                    // Заголовки
                                    HStack(spacing: 5) {
                                        Text("")
                                            .frame(width: 60)
                                        ForEach(0..<selectedImages.count, id: \.self) { i in
                                            Text("\(i + 1)")
                                                .font(.caption)
                                                .frame(width: 40)
                                        }
                                    }
                                    
                                    // Строки матрицы
                                    ForEach(0..<selectedImages.count, id: \.self) { i in
                                        HStack(spacing: 5) {
                                            Text("\(i + 1)")
                                                .font(.caption)
                                                .frame(width: 60)
                                            
                                            ForEach(0..<selectedImages.count, id: \.self) { j in
                                                if i == j {
                                                    Text("—")
                                                        .font(.caption)
                                                        .frame(width: 40)
                                                        .foregroundColor(.gray)
                                                } else if similarities.indices.contains(i) && similarities[i].indices.contains(j) {
                                                    let similarity = similarities[i][j]
                                                    Text("\(Int(similarity * 100))%")
                                                        .font(.caption)
                                                        .frame(width: 40)
                                                        .foregroundColor(similarityColor(for: similarity))
                                                        .background(similarityColor(for: similarity).opacity(0.2))
                                                        .cornerRadius(4)
                                                } else {
                                                    Text("—")
                                                        .font(.caption)
                                                        .frame(width: 40)
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding()
                            }
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                }
            }
            .padding()
        }
        .onChange(of: selectedItems) { _, newItems in
            Task {
                var newImages: [UIImage] = []
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        newImages.append(image)
                    }
                }
                selectedImages = newImages
                embeddingService.embeddings = []
                similarities = []
                selectedImage1Index = 0
                selectedImage2Index = min(1, selectedImages.count - 1)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func selectImageForComparison(index: Int) {
        if selectedImage1Index == index {
            // Если нажали на первое изображение, переключаем на второе
            if selectedImage2Index != index {
                selectedImage1Index = selectedImage2Index
                selectedImage2Index = index
            }
        } else if selectedImage2Index == index {
            // Если нажали на второе изображение, переключаем на первое
            if selectedImage1Index != index {
                selectedImage2Index = selectedImage1Index
                selectedImage1Index = index
            }
        } else {
            // Если нажали на новое изображение, делаем его первым
            selectedImage1Index = index
        }
    }
    
    private func generateAllEmbeddings() {
        isGeneratingEmbeddings = true
        
        Task {
            _ = await embeddingService.generateEmbeddings(from: selectedImages)
            
            await MainActor.run {
                isGeneratingEmbeddings = false
            }
        }
    }
    
    private func compareSelectedImages() {
        guard selectedImage1Index < embeddingService.embeddings.count && selectedImage2Index < embeddingService.embeddings.count else { return }
        
        isComparing = true
        similarities = []
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let result = embeddingService.compareEmbeddings(embeddingService.embeddings[selectedImage1Index], embeddingService.embeddings[selectedImage2Index])
            similarities = [[result]]
            isComparing = false
        }
    }
    
    // MARK: - Computed Properties
    
    private func similarityColor(for similarity: Float) -> Color {
        switch similarity {
        case 0.8...1.0:
            return .green
        case 0.5..<0.8:
            return .orange
        case 0.0..<0.5:
            return .red
        default:
            return .gray
        }
    }
    
    private func similarityDescription(for similarity: Float) -> String {
        switch similarity {
        case 0.9...1.0:
            return "Очень похожие изображения! Почти идентичны."
        case 0.8..<0.9:
            return "Очень похожие изображения."
        case 0.6..<0.8:
            return "Похожие изображения."
        case 0.4..<0.6:
            return "Умеренно похожие изображения."
        case 0.2..<0.4:
            return "Слабо похожие изображения."
        case 0.0..<0.2:
            return "Разные изображения."
        default:
            return "Не удалось сравнить."
        }
    }
}

#Preview {
    ContentView()
}
