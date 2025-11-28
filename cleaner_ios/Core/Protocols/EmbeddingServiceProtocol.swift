import Foundation
import CoreVideo
import Photos

protocol EmbeddingServiceProtocol {
    func generateImageEmbedding(from pixelBuffer: CVPixelBuffer) async -> Result<[Float], EmbeddingError>
    func generateTextEmbedding(from text: String) async -> Result<[Float], EmbeddingError>
    func generateEmbeddingFromAsset(_ asset: PHAsset) async -> Result<[Float], EmbeddingError>
    func calculateSimilarity(_ embedding1: [Float], _ embedding2: [Float]) -> Float
}

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

