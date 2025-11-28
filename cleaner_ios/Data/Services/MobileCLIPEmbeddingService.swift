import Foundation
import CoreVideo
import Photos

final class MobileCLIPEmbeddingService: EmbeddingServiceProtocol {
    private let embeddingGenerator: EmbeddingGenerator
    private let similarityCalculator: SimilarityCalculator
    private let imageProcessor: ImageProcessingProtocol
    
    init(
        embeddingGenerator: EmbeddingGenerator,
        similarityCalculator: SimilarityCalculator,
        imageProcessor: ImageProcessingProtocol
    ) {
        self.embeddingGenerator = embeddingGenerator
        self.similarityCalculator = similarityCalculator
        self.imageProcessor = imageProcessor
    }
    
    func generateImageEmbedding(from pixelBuffer: CVPixelBuffer) async -> Result<[Float], EmbeddingError> {
        await embeddingGenerator.generateImageEmbedding(from: pixelBuffer)
    }
    
    func generateTextEmbedding(from text: String) async -> Result<[Float], EmbeddingError> {
        await embeddingGenerator.generateTextEmbedding(from: text)
    }
    
    func calculateSimilarity(_ embedding1: [Float], _ embedding2: [Float]) -> Float {
        similarityCalculator.cosineSimilarity(embedding1, embedding2)
    }
    
    func generateEmbeddingFromAsset(_ asset: PHAsset) async -> Result<[Float], EmbeddingError> {
        let pixelBufferResult = await imageProcessor.convertAssetToPixelBuffer(
            asset,
            targetSize: CGSize(width: 256, height: 256)
        )
        
        switch pixelBufferResult {
        case .success(let pixelBuffer):
            return await generateImageEmbedding(from: pixelBuffer)
        case .failure(let error):
            return .failure(.predictionFailed(error))
        }
    }
}
