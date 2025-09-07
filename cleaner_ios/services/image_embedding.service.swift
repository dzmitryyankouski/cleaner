import Foundation
import Vision
import CoreML
import UIKit

class ImageEmbeddingService: ObservableObject {
    private var mobileClipModel: MLModel?
    
    @Published var embeddings: [[Float]] = []
    @Published var clusterIndexService = ClusterIndexService()
    @Published var useClustering = true

    init() {
        guard Bundle.main.url(forResource: "mobileclip_s0_image", withExtension: "mlmodelc") != nil else {
            print("❌ Model not found in Bundle")
            return
        }

        if let modelURL = Bundle.main.url(forResource: "mobileclip_s0_image", withExtension: "mlmodelc") {
            do {
                mobileClipModel = try MLModel(contentsOf: modelURL)
            } catch {
                print("❌ Error loading model from Bundle: \(error)")
            }
        }
    }

    func generateEmbedding(from image: UIImage) -> [Float] {
        guard let mobileClipModel = mobileClipModel else {
            print("❌ Model not loaded")
            return []
        }

        guard let cgImage = image.cgImage else {
            print("❌ Error getting cgImage")
            return []
        }

        var result: [Float] = []
        let semaphore = DispatchSemaphore(value: 0)

        let request = VNCoreMLRequest(model: try! VNCoreMLModel(for: mobileClipModel)) { request, error in
             DispatchQueue.main.async {
                
                if let error = error {
                    print("❌ Error: \(error)")
                    semaphore.signal()
                    return
                }
                
                guard let results = request.results as? [VNCoreMLFeatureValueObservation],
                      let firstResult = results.first,
                      let multiArray = firstResult.featureValue.multiArrayValue else {
                    print("❌ Error getting embedding")
                    semaphore.signal()
                    return
                }
                
                result = self.convertMultiArrayToFloatArray(multiArray)
                self.embeddings.append(result)
                print("✅ Embedding generated: \(result)")
                semaphore.signal()
            }
        }
        
        request.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("❌ Error: \(error)")
                semaphore.signal()
            }
        }
        
        semaphore.wait()
        return result
    }

    func generateEmbeddings(from images: [UIImage]) async -> [[Float]] {
        // Очищаем предыдущие эмбеддинги
        await MainActor.run {
            embeddings = []
        }
        
        var results: [[Float]] = []
        
        for image in images {
            let embedding = generateEmbedding(from: image)
            results.append(embedding)
        }
        
        // Если включена кластеризация, добавляем эмбеддинги в кластерный индекс
        if useClustering && !results.isEmpty {
            let imageIndices = Array(0..<results.count)
            await clusterIndexService.addEmbeddings(results, imageIndices: imageIndices)
        }
        
        return results
    }

    private func convertMultiArrayToFloatArray(_ multiArray: MLMultiArray) -> [Float] {
        let count = multiArray.count
        var result = [Float](repeating: 0, count: count)
        
        for i in 0..<count {
            result[i] = Float(truncating: multiArray[i])
        }
        
        return result
    }
    
    /// Сравнивает два эмбеддинга и возвращает коэффициент сходства (от 0 до 1)
    /// 1.0 означает идентичные эмбеддинги, 0.0 означает полностью разные
    func compareEmbeddings(_ embedding1: [Float], _ embedding2: [Float]) -> Float {
        // Проверяем, что эмбеддинги имеют одинаковую размерность
        guard embedding1.count == embedding2.count else {
            print("❌ Размерности эмбеддингов не совпадают: \(embedding1.count) vs \(embedding2.count)")
            return 0.0
        }
        
        // Вычисляем косинусное сходство
        let cosineSimilarity = calculateCosineSimilarity(embedding1, embedding2)
        
        // Преобразуем в диапазон от 0 до 1 (косинусное сходство может быть от -1 до 1)
        let normalizedSimilarity = (cosineSimilarity + 1.0) / 2.0
        
        print("✅ Коэффициент сходства эмбеддингов: \(normalizedSimilarity)")
        return normalizedSimilarity
    }
    
    /// Вычисляет косинусное сходство между двумя векторами
    private func calculateCosineSimilarity(_ vector1: [Float], _ vector2: [Float]) -> Float {
        var dotProduct: Float = 0.0
        var norm1: Float = 0.0
        var norm2: Float = 0.0
        
        for i in 0..<vector1.count {
            dotProduct += vector1[i] * vector2[i]
            norm1 += vector1[i] * vector1[i]
            norm2 += vector2[i] * vector2[i]
        }
        
        let magnitude1 = sqrt(norm1)
        let magnitude2 = sqrt(norm2)
        
        // Избегаем деления на ноль
        guard magnitude1 > 0 && magnitude2 > 0 else {
            return 0.0
        }
        
        return dotProduct / (magnitude1 * magnitude2)
    }
    
    // MARK: - Clustering Methods
    
    /// Находит похожие изображения используя кластеризованный индекс
    func findSimilarImages(to imageIndex: Int, maxResults: Int = 5, similarityThreshold: Float = 0.7) -> [SimilarityResult] {
        guard imageIndex < embeddings.count else {
            print("❌ Неверный индекс изображения: \(imageIndex)")
            return []
        }
        
        let queryEmbedding = embeddings[imageIndex]
        
        if useClustering {
            return clusterIndexService.findSimilarEmbeddings(
                to: queryEmbedding,
                maxResults: maxResults,
                similarityThreshold: similarityThreshold
            )
        } else {
            // Fallback к обычному поиску
            return findSimilarImagesBruteForce(queryEmbedding: queryEmbedding, maxResults: maxResults, similarityThreshold: similarityThreshold)
        }
    }
    
    /// Находит похожие изображения полным перебором (fallback)
    private func findSimilarImagesBruteForce(queryEmbedding: [Float], maxResults: Int, similarityThreshold: Float) -> [SimilarityResult] {
        var results: [SimilarityResult] = []
        
        for (index, embedding) in embeddings.enumerated() {
            let similarity = calculateCosineSimilarity(queryEmbedding, embedding)
            if similarity >= similarityThreshold {
                let indexedEmbedding = IndexedEmbedding(embedding: embedding, imageIndex: index)
                results.append(SimilarityResult(embedding: indexedEmbedding, similarity: similarity, clusterId: nil))
            }
        }
        
        return results
            .sorted { $0.similarity > $1.similarity }
            .prefix(maxResults)
            .map { $0 }
    }
    
    /// Переключает использование кластеризации
    func toggleClustering() {
        useClustering.toggle()
        print("🔄 Кластеризация \(useClustering ? "включена" : "отключена")")
    }
    
    /// Принудительно пересчитывает кластеры
    func recalculateClusters() async {
        guard useClustering else {
            print("⚠️ Кластеризация отключена")
            return
        }
        
        print("🔄 Принудительный пересчет кластеров...")
        await clusterIndexService.performClustering()
    }
    
    /// Получает статистику кластеризации
    func getClusteringStats() -> ClusteringStats? {
        return clusterIndexService.getClusteringStats()
    }
    
    /// Получает количество кластеров
    func getClusterCount() -> Int {
        return clusterIndexService.getClusterCount()
    }
    
    /// Очищает все данные кластеризации
    func clearClusteringData() {
        clusterIndexService.clearAll()
        print("🗑️ Данные кластеризации очищены")
    }
    
    /// Получает группы похожих изображений, сгруппированные по кластерам
    func getSimilarImageGroups(for imageIndex: Int, similarityThreshold: Float = 0.5) -> [ImageGroup] {
        guard imageIndex < embeddings.count else {
            print("❌ Неверный индекс изображения: \(imageIndex)")
            return []
        }
        
        let queryEmbedding = embeddings[imageIndex]
        
        if useClustering {
            return clusterIndexService.getImageGroups(for: queryEmbedding, similarityThreshold: similarityThreshold)
        } else {
            // Fallback к обычному поиску
            return getImageGroupsBruteForce(queryEmbedding: queryEmbedding, similarityThreshold: similarityThreshold)
        }
    }
    
    /// Получает группы изображений полным перебором (fallback)
    private func getImageGroupsBruteForce(queryEmbedding: [Float], similarityThreshold: Float) -> [ImageGroup] {
        var results: [SimilarityResult] = []
        
        for (index, embedding) in embeddings.enumerated() {
            let similarity = calculateCosineSimilarity(queryEmbedding, embedding)
            if similarity >= similarityThreshold {
                let indexedEmbedding = IndexedEmbedding(embedding: embedding, imageIndex: index)
                results.append(SimilarityResult(embedding: indexedEmbedding, similarity: similarity, clusterId: nil))
            }
        }
        
        // Группируем по уровню сходства
        let sortedResults = results.sorted { $0.similarity > $1.similarity }
        
        // Создаем одну группу для всех результатов
        let group = ImageGroup(
            id: UUID(),
            title: "Похожие изображения",
            images: sortedResults,
            averageSimilarity: sortedResults.isEmpty ? 0 : sortedResults.map { $0.similarity }.reduce(0, +) / Float(sortedResults.count)
        )
        
        return [group]
    }
    
}