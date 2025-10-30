import Foundation
import CoreML
import CoreVideo

// MARK: - Embedding Generator

/// Генератор эмбедингов для изображений и текста
final class EmbeddingGenerator {
    
    // MARK: - Properties
    
    private let imageModel: Any
    private let textModel: Any
    private let tokenizer: CLIPTokenizer
    
    // MARK: - Initialization
    
    init(imageModel: Any, textModel: Any, tokenizer: CLIPTokenizer) {
        self.imageModel = imageModel
        self.textModel = textModel
        self.tokenizer = tokenizer
    }
    
    // MARK: - Public Methods
    
    /// Генерирует эмбединг из изображения
    func generateImageEmbedding(from pixelBuffer: CVPixelBuffer) async -> Result<[Float], EmbeddingError> {
        do {
            // Проверяем тип модели и вызываем соответствующий метод
            if let s0Model = imageModel as? mobileclip_s0_image {
                let output = try await s0Model.prediction(image: pixelBuffer)
                return .success(convertMultiArrayToFloatArray(output.final_emb_1))
            } else if let s1Model = imageModel as? mobileclip_s1_image {
                let output = try await s1Model.prediction(image: pixelBuffer)
                return .success(convertMultiArrayToFloatArray(output.final_emb_1))
            } else if let s2Model = imageModel as? mobileclip_s2_image {
                let output = try await s2Model.prediction(image: pixelBuffer)
                return .success(convertMultiArrayToFloatArray(output.final_emb_1))
            } else {
                return .failure(.modelNotLoaded("unknown image model type"))
            }
        } catch {
            return .failure(.predictionFailed(error))
        }
    }
    
    /// Генерирует эмбединг из текста
    func generateTextEmbedding(from text: String) async -> Result<[Float], EmbeddingError> {
        do {
            let inputIds = tokenizer.encode_full(text: text)
            let inputArray = try MLMultiArray(shape: [1, 77], dataType: .int32)
            
            for (index, element) in inputIds.enumerated() {
                inputArray[index] = NSNumber(value: element)
            }
            
            // Проверяем тип модели и вызываем соответствующий метод
            if let s0Model = textModel as? mobileclip_s0_text {
                let output = try s0Model.prediction(text: inputArray)
                return .success(convertMultiArrayToFloatArray(output.final_emb_1))
            } else if let s1Model = textModel as? mobileclip_s1_text {
                let output = try s1Model.prediction(text: inputArray)
                return .success(convertMultiArrayToFloatArray(output.final_emb_1))
            } else if let s2Model = textModel as? mobileclip_s2_text {
                let output = try s2Model.prediction(text: inputArray)
                return .success(convertMultiArrayToFloatArray(output.final_emb_1))
            } else {
                return .failure(.modelNotLoaded("unknown text model type"))
            }
        } catch {
            return .failure(.predictionFailed(error))
        }
    }
    
    // MARK: - Private Methods
    
    private func convertMultiArrayToFloatArray(_ multiArray: MLMultiArray) -> [Float] {
        let count = multiArray.count
        var result = [Float](repeating: 0, count: count)
        
        for i in 0..<count {
            result[i] = Float(truncating: multiArray[i])
        }
        
        return result
    }
}

