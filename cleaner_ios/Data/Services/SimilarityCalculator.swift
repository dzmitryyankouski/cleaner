import Foundation
import Accelerate

// MARK: - Similarity Calculator

/// Калькулятор схожести между эмбедингами
final class SimilarityCalculator {
    
    // MARK: - Public Methods
    
    /// Вычисляет косинусное сходство между двумя эмбедингами
    /// - Returns: Значение от -1 до 1, где 1 означает полное сходство
    func cosineSimilarity(_ embedding1: [Float], _ embedding2: [Float]) -> Float {
        guard embedding1.count == embedding2.count else {
            return 0.0
        }
        
        #if canImport(Accelerate)
        return cosineSimilarityAccelerate(embedding1, embedding2)
        #else
        return cosineSimilarityManual(embedding1, embedding2)
        #endif
    }
    
    // MARK: - Private Methods
    
    #if canImport(Accelerate)
    private func cosineSimilarityAccelerate(_ a: [Float], _ b: [Float]) -> Float {
        var dotProduct: Float = 0
        vDSP_dotpr(a, 1, b, 1, &dotProduct, vDSP_Length(a.count))
        
        var norm1: Float = 0
        vDSP_svesq(a, 1, &norm1, vDSP_Length(a.count))
        
        var norm2: Float = 0
        vDSP_svesq(b, 1, &norm2, vDSP_Length(b.count))
        
        let magnitude = sqrt(norm1) * sqrt(norm2)
        guard magnitude > 0 else { return 0.0 }
        
        return dotProduct / magnitude
    }
    #endif
    
    private func cosineSimilarityManual(_ a: [Float], _ b: [Float]) -> Float {
        var dotProduct: Float = 0.0
        var norm1: Float = 0.0
        var norm2: Float = 0.0
        
        for i in 0..<a.count {
            dotProduct += a[i] * b[i]
            norm1 += a[i] * a[i]
            norm2 += b[i] * b[i]
        }
        
        let magnitude = sqrt(norm1) * sqrt(norm2)
        guard magnitude > 0 else { return 0.0 }
        
        return dotProduct / magnitude
    }
}

