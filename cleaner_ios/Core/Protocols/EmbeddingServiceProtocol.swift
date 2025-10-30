import Foundation
import CoreVideo

// MARK: - Embedding Service Protocol

/// Протокол для работы с генерацией эмбедингов изображений и текста
protocol EmbeddingServiceProtocol {
    /// Генерирует эмбединг из изображения
    func generateImageEmbedding(from pixelBuffer: CVPixelBuffer) async -> Result<[Float], EmbeddingError>
    
    /// Генерирует эмбединг из текста
    func generateTextEmbedding(from text: String) async -> Result<[Float], EmbeddingError>
    
    /// Вычисляет косинусное сходство между двумя эмбедингами
    func calculateSimilarity(_ embedding1: [Float], _ embedding2: [Float]) -> Float
}

// MARK: - Embedding Error

enum EmbeddingError: LocalizedError {
    case modelNotLoaded(String)
    case tokenizerNotAvailable
    case invalidInput
    case encodingFailed
    case predictionFailed(Error)
    case dimensionMismatch
    
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded(let model):
            return "Модель \(model) не загружена"
        case .tokenizerNotAvailable:
            return "Токенизатор недоступен"
        case .invalidInput:
            return "Некорректные входные данные"
        case .encodingFailed:
            return "Ошибка кодирования"
        case .predictionFailed(let error):
            return "Ошибка предсказания: \(error.localizedDescription)"
        case .dimensionMismatch:
            return "Несовпадение размерностей эмбедингов"
        }
    }
}

