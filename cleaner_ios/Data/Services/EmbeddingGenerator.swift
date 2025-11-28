import Foundation
import CoreML
import CoreVideo

final class EmbeddingGenerator {
    private let imageModel: mobileclip_s2_image
    private let textModel: mobileclip_s2_text
    private let tokenizer: CLIPTokenizer
    
    init(tokenizer: CLIPTokenizer) throws {
        self.tokenizer = tokenizer
        
        do {
            self.imageModel = try mobileclip_s2_image()
        } catch {
            throw EmbeddingError.modelNotLoaded("image model: \(error.localizedDescription)")
        }
        
        do {
            self.textModel = try mobileclip_s2_text()
        } catch {
            throw EmbeddingError.modelNotLoaded("text model: \(error.localizedDescription)")
        }
    }
    
    func generateImageEmbedding(from pixelBuffer: CVPixelBuffer) async -> Result<[Float], EmbeddingError> {
        do {
            let output = try await imageModel.prediction(image: pixelBuffer)
            return .success(convertMultiArrayToFloatArray(output.final_emb_1))
        } catch {
            return .failure(.predictionFailed(error))
        }
    }
    
    func generateTextEmbedding(from text: String) async -> Result<[Float], EmbeddingError> {
        do {
            let inputIds = tokenizer.encode_full(text: text)
            let inputArray = try MLMultiArray(shape: [1, 77], dataType: .int32)
            
            for (index, element) in inputIds.enumerated() {
                inputArray[index] = NSNumber(value: element)
            }
            
            let output = try textModel.prediction(text: inputArray)
            return .success(convertMultiArrayToFloatArray(output.final_emb_1))
        } catch {
            return .failure(.predictionFailed(error))
        }
    }
    
    private func convertMultiArrayToFloatArray(_ multiArray: MLMultiArray) -> [Float] {
        let count = multiArray.count
        var result = [Float](repeating: 0, count: count)
        
        for i in 0..<count {
            result[i] = Float(truncating: multiArray[i])
        }
        
        return result
    }
}
