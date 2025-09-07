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
    @State private var isGeneratingEmbeddings = false
    @State private var isSearchingSimilar = false
    @State private var similarGroups: [[Int]] = [] // Группы похожих изображений
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Text("Сравнение изображений")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Кнопка выбора изображений
                PhotosPicker(selection: $selectedItems, maxSelectionCount: 20, matching: .images) {
                    Label("Выбрать изображения", systemImage: "photo.on.rectangle.angled")
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
                
                // Кнопка генерации эмбеддингов
                if !selectedImages.isEmpty {
                    Button(action: {
                        generateEmbeddings()
                    }) {
                        HStack {
                            if isGeneratingEmbeddings {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            }
                            Text(isGeneratingEmbeddings ? "Генерируем эмбеддинги..." : "Сгенерировать эмбеддинги")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(embeddingService.embeddings.count == selectedImages.count ? Color.gray : Color.green)
                        .cornerRadius(10)
                    }
                    .disabled(isGeneratingEmbeddings || embeddingService.embeddings.count == selectedImages.count)
                }
                
                // Переключатель кластеризации
                if !selectedImages.isEmpty {
                    HStack {
                        Toggle("Использовать кластеризацию", isOn: $embeddingService.useClustering)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("Кластеров: \(embeddingService.getClusterCount())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                
                // Кнопка поиска похожих изображений
                if embeddingService.embeddings.count == selectedImages.count && !selectedImages.isEmpty {
                    Button(action: {
                        findSimilarImages()
                    }) {
                        HStack {
                            if isSearchingSimilar {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            }
                            Text(isSearchingSimilar ? "Ищем похожие..." : "Найти похожие изображения")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(10)
                    }
                    .disabled(isSearchingSimilar)
                }
                
                // Отображение групп похожих изображений
                if !similarGroups.isEmpty {
                    VStack(spacing: 20) {
                        Text("Похожие изображения")
                            .font(.headline)
                            .padding(.top)
                        
                        ForEach(Array(similarGroups.enumerated()), id: \.offset) { groupIndex, group in
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Группа \(groupIndex + 1)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(group, id: \.self) { imageIndex in
                                            VStack(spacing: 5) {
                                                Image(uiImage: selectedImages[imageIndex])
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 80, height: 80)
                                                    .cornerRadius(8)
                                                
                                                Text("\(imageIndex + 1)")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding()
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
                similarGroups = []
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func generateEmbeddings() {
        isGeneratingEmbeddings = true
        
        Task {
            _ = await embeddingService.generateEmbeddings(from: selectedImages)
            
            await MainActor.run {
                isGeneratingEmbeddings = false
            }
        }
    }
    
    private func findSimilarImages() {
        guard !selectedImages.isEmpty else { return }
        
        isSearchingSimilar = true
        similarGroups = []
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("🔍 Ищем похожие изображения с помощью кластеризации...")
            
            // Используем кластеризацию для группировки
            if self.embeddingService.useClustering {
                // Получаем группы через кластеризацию
                var allGroups: [[Int]] = []
                
                for i in 0..<self.selectedImages.count {
                    let groups = self.embeddingService.getSimilarImageGroups(
                        for: i,
                        similarityThreshold: 0.7
                    )
                    
                    // Преобразуем ImageGroup в простые массивы индексов
                    for group in groups {
                        let indices = group.images.map { $0.embedding.imageIndex }
                        if indices.count > 1 {
                            allGroups.append(indices)
                        }
                    }
                }
                
                // Объединяем дублирующиеся группы
                self.similarGroups = self.mergeDuplicateGroups(allGroups)
            } else {
                // Fallback к простому алгоритму
                var groups: [[Int]] = []
                var used: Set<Int> = []
                let similarityThreshold: Float = 0.7
                
                for i in 0..<self.selectedImages.count {
                    if used.contains(i) { continue }
                    
                    var currentGroup: [Int] = [i]
                    used.insert(i)
                    
                    for j in (i+1)..<self.selectedImages.count {
                        if used.contains(j) { continue }
                        
                        let similarity = self.embeddingService.compareEmbeddings(
                            self.embeddingService.embeddings[i],
                            self.embeddingService.embeddings[j]
                        )
                        
                        if similarity >= similarityThreshold {
                            currentGroup.append(j)
                            used.insert(j)
                        }
                    }
                    
                    if currentGroup.count > 1 {
                        groups.append(currentGroup)
                    }
                }
                
                self.similarGroups = groups
            }
            
            self.isSearchingSimilar = false
            print("✅ Найдено \(self.similarGroups.count) групп похожих изображений")
        }
    }
    
    private func mergeDuplicateGroups(_ groups: [[Int]]) -> [[Int]] {
        var mergedGroups: [Set<Int>] = []
        
        for group in groups {
            let groupSet = Set(group)
            var merged = false
            
            for i in 0..<mergedGroups.count {
                if !mergedGroups[i].isDisjoint(with: groupSet) {
                    mergedGroups[i] = mergedGroups[i].union(groupSet)
                    merged = true
                    break
                }
            }
            
            if !merged {
                mergedGroups.append(groupSet)
            }
        }
        
        return mergedGroups.map { Array($0).sorted() }.filter { $0.count > 1 }
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Сравнение изображений")
            .font(.largeTitle)
            .fontWeight(.bold)
        
        Text("Выберите изображения для сравнения")
            .font(.headline)
            .foregroundColor(.primary)
        
        Button("Выбрать изображения (до 20)") {
            // Действие
        }
        .font(.headline)
        .foregroundColor(.white)
        .padding()
        .background(Color.blue)
        .cornerRadius(10)
        
        Text("Приложение готово к работе")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding()
        
        Text("Поддерживает множественный выбор и кластеризацию")
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
    }
    .padding()
}
