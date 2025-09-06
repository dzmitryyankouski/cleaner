//
//  ImageEmbeddingService.swift
//  cleaner_ios
//
//  Created by Dmitriy Yankovskiy on 06/09/2025.
//

import Foundation
import Vision
import CoreML
import UIKit

class ImageEmbeddingService: ObservableObject {
    @Published var isProcessing = false
    @Published var embedding: [Float]?
    @Published var errorMessage: String?
    
    init() {
        // Инициализация без внешних моделей
    }
    
    func generateEmbedding(from image: UIImage) {
        isProcessing = true
        errorMessage = nil
        
        guard let cgImage = image.cgImage else {
            errorMessage = "Не удалось получить изображение"
            isProcessing = false
            return
        }
        
        // Используем Vision framework для извлечения признаков изображения
        let request = VNGenerateImageFeaturePrintRequest { [weak self] request, error in
            DispatchQueue.main.async {
                self?.isProcessing = false
                
                if let error = error {
                    self?.errorMessage = "Ошибка обработки изображения: \(error.localizedDescription)"
                    return
                }
                
                guard let results = request.results as? [VNFeaturePrintObservation],
                      let firstResult = results.first else {
                    self?.errorMessage = "Не удалось получить эмбединг"
                    return
                }
                
                // Конвертируем VNFeaturePrintObservation в массив Float
                let embedding = self?.convertFeaturePrintToFloatArray(firstResult) ?? []
                self?.embedding = embedding
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.errorMessage = "Ошибка выполнения запроса: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func convertFeaturePrintToFloatArray(_ featurePrint: VNFeaturePrintObservation) -> [Float] {
        // VNFeaturePrintObservation содержит данные в формате Data
        // Конвертируем их в массив Float для демонстрации
        let data = featurePrint.data
        let count = data.count / MemoryLayout<Float>.size
        var result = [Float](repeating: 0, count: count)
        
        data.withUnsafeBytes { bytes in
            let floatPointer = bytes.bindMemory(to: Float.self)
            for i in 0..<count {
                result[i] = floatPointer[i]
            }
        }
        
        return result
    }
    
    func getEmbeddingAsString() -> String {
        guard let embedding = embedding else { return "Эмбединг не сгенерирован" }
        
        let formattedValues = embedding.map { String(format: "%.4f", $0) }
        return "Эмбединг (\(embedding.count) измерений):\n" + formattedValues.joined(separator: ", ")
    }
    
    func getEmbeddingStatistics() -> String {
        guard let embedding = embedding else { return "Нет данных" }
        
        let min = embedding.min() ?? 0
        let max = embedding.max() ?? 0
        let mean = embedding.reduce(0, +) / Float(embedding.count)
        
        return """
        Размерность: \(embedding.count)
        Минимум: \(String(format: "%.4f", min))
        Максимум: \(String(format: "%.4f", max))
        Среднее: \(String(format: "%.4f", mean))
        """
    }
}

// Примечание: Для использования настоящей MobileCLIP модели:
// 1. Скачайте Core ML версию MobileCLIP модели
// 2. Добавьте её в проект Xcode
// 3. Замените VNGenerateImageFeaturePrintRequest на VNCoreMLRequest с вашей моделью
// 4. Обновите метод convertFeaturePrintToFloatArray для работы с MLMultiArray
