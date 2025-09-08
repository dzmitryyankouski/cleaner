//
//  cleaner_iosTests.swift
//  cleaner_iosTests
//
//  Created by Dmitriy Yankovskiy on 06/09/2025.
//

import Testing
@testable import cleaner_ios

struct cleaner_iosTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test func testTextToEmbedding() async throws {
        let service = ImageEmbeddingService()
        let testText = "a beautiful sunset over the ocean"
        
        let embedding = await service.textToEmbedding(text: testText)
        
        // Проверяем, что эмбединг сгенерирован
        #expect(!embedding.isEmpty, "Text embedding should not be empty")
        
        // Проверяем, что размерность эмбединга разумная (обычно 512 для MobileCLIP)
        #expect(embedding.count > 0, "Embedding should have positive dimension")
        #expect(embedding.count <= 1024, "Embedding dimension should be reasonable")
        
        print("✅ Text embedding test passed. Dimension: \(embedding.count)")
    }
    
    @Test func testCosineSimilarity() async throws {
        let service = ImageEmbeddingService()
        
        // Создаем два одинаковых эмбединга
        let embedding1: [Float] = [1.0, 2.0, 3.0, 4.0]
        let embedding2: [Float] = [1.0, 2.0, 3.0, 4.0]
        
        let similarity = service.cosineSimilarity(embedding1, embedding2)
        
        // Косинусное сходство одинаковых векторов должно быть 1.0
        #expect(abs(similarity - 1.0) < 0.001, "Identical embeddings should have similarity close to 1.0")
        
        // Тест с ортогональными векторами
        let embedding3: [Float] = [1.0, 0.0, 0.0, 0.0]
        let embedding4: [Float] = [0.0, 1.0, 0.0, 0.0]
        
        let orthogonalSimilarity = service.cosineSimilarity(embedding3, embedding4)
        
        // Ортогональные векторы должны иметь сходство близкое к 0
        #expect(abs(orthogonalSimilarity) < 0.001, "Orthogonal embeddings should have similarity close to 0")
        
        print("✅ Cosine similarity test passed")
    }

}
