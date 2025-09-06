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
    
    private var mobileClipModel: MLModel?
    private var compiledModelURL: URL?
    
    init() {
        // Сначала попробуем скопировать модель в Bundle если её там нет
        loadMobileClipModel()
    }

    
    private func loadMobileClipModel() {
        print("🔍 Загружаем предварительно скомпилированную модель MobileCLIP...")

        // Сначала пробуем загрузить из Bundle (если добавлена)
        if let modelURL = Bundle.main.url(forResource: "mobileclip_s0_image", withExtension: "mlmodelc") {
            do {
                mobileClipModel = try MLModel(contentsOf: modelURL)
                print("✅ Модель MobileCLIP загружена из Bundle!")
                return
            } catch {
                print("❌ Ошибка загрузки модели из Bundle: \(error)")
            }
        }
        
        // Если ничего не сработало
        errorMessage = "Не удалось найти предварительно скомпилированную модель MobileCLIP"
        print("❌ Все способы загрузки модели не удались")
    }
    
    func generateEmbedding(from image: UIImage) {
        isProcessing = true
        errorMessage = nil
        
        guard let mobileClipModel = mobileClipModel else {
            errorMessage = "Модель MobileCLIP не загружена"
            isProcessing = false
            return
        }
        
        guard let cgImage = image.cgImage else {
            errorMessage = "Не удалось получить изображение"
            isProcessing = false
            return
        }
        
        // Используем Vision framework с моделью MobileCLIP
        let request = VNCoreMLRequest(model: try! VNCoreMLModel(for: mobileClipModel)) { [weak self] request, error in
            DispatchQueue.main.async {
                self?.isProcessing = false
                
                if let error = error {
                    self?.errorMessage = "Ошибка обработки изображения: \(error.localizedDescription)"
                    return
                }
                
                guard let results = request.results as? [VNCoreMLFeatureValueObservation],
                      let firstResult = results.first,
                      let multiArray = firstResult.featureValue.multiArrayValue else {
                    self?.errorMessage = "Не удалось получить эмбединг"
                    return
                }
                
                // Конвертируем MLMultiArray в массив Float
                let embedding = self?.convertMultiArrayToFloatArray(multiArray) ?? []
                self?.embedding = embedding
            }
        }
        
        // Настройки для обработки изображения
        request.imageCropAndScaleOption = .centerCrop
        
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
    
    private func convertMultiArrayToFloatArray(_ multiArray: MLMultiArray) -> [Float] {
        // Конвертируем MLMultiArray в массив Float
        let count = multiArray.count
        var result = [Float](repeating: 0, count: count)
        
        for i in 0..<count {
            result[i] = Float(truncating: multiArray[i])
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

// MobileCLIP S0 модель интегрирована и готова к использованию
// Модель автоматически загружается при инициализации сервиса
// Эмбединги генерируются с использованием Vision framework и Core ML
