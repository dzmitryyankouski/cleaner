import Foundation
@preconcurrency import Vision
import CoreML
import UIKit
import Photos
import NaturalLanguage
import CoreVideo

class ImageEmbeddingService {
    private var mobileClipImageModel: mobileclip_s0_image?
    private var mobileClipTextModel: mobileclip_s0_text?
    private var concurrentTasks = 10

    var tokenizer: CLIPTokenizer?
    
    init() {
        loadImageModel()
        loadTextModel()
        loadTokenizer()
    }
    
    private func loadTokenizer() {
        do {
            tokenizer = try CLIPTokenizer()
            print("✅ CLIP токенизатор загружен!")
        } catch {
            print("❌ Ошибка загрузки токенизатора: \(error)")
            tokenizer = nil
        }
    }
    
    private func loadImageModel() {
        do {
            mobileClipImageModel = try mobileclip_s0_image()
            print("Image Model loaded")
        } catch {
            print("❌ Ошибка загрузки модели изображений из Bundle: \(error)")
        }
    }
    
    private func loadTextModel() {
        do {
            mobileClipTextModel = try mobileclip_s0_text()
            print("Text Model loaded")
        } catch {
            print("❌ Ошибка загрузки модели текста из Bundle: \(error)")
        }
    }

    func indexPhotos(assets: [PHAsset], onItemCompleted: ((Int, [Float]) -> Void)? = nil) async {
        print("🔄 Начинаем индексацию \(assets.count) фотографий...")

        var embeddings: [[Float]] = []
        
        // Обрабатываем каждый ассет в отдельной таске с ограничением
        await withTaskGroup(of: (Int, [Float]?)?.self) { group in
            var activeTasks = 0
            
            for (index, asset) in assets.enumerated() {
                // Ждем, пока освободится место для новой таски
                while activeTasks >= concurrentTasks {
                    if let result = await group.next() {
                        if let (assetIndex, embedding) = result, let embedding = embedding {
                            embeddings.append(embedding)

                            await MainActor.run {
                                onItemCompleted?(assetIndex, embedding)
                            }
                        }
                        activeTasks -= 1
                    }
                }
                
                group.addTask {
                    let embedding = await self.processSingleAsset(asset)
                    return (index, embedding)
                }
                activeTasks += 1
            }
            
            // Обрабатываем оставшиеся результаты
            for await result in group {
                if let (assetIndex, embedding) = result, let embedding = embedding {
                    // Обновляем UI в реальном времени
                    await MainActor.run {
                        embeddings.append(embedding)
                        onItemCompleted?(assetIndex, embedding)
                    }
                }
            }
        }
    }

    func generateEmbedding(from pixelBuffer: CVPixelBuffer) async -> [Float] {
        do {
            guard let mobileClipImageModel = mobileClipImageModel else {
                print("❌ Image model not loaded")
                return []
            }
            
            let output = try await mobileClipImageModel.prediction(image: pixelBuffer)
            
            // Конвертируем MLMultiArray в [Float]
            let count = output.final_emb_1.count
            var result = [Float](repeating: 0, count: count)
            
            for i in 0..<count {
                result[i] = Float(truncating: output.final_emb_1[i])
            }
            
            return result
        } catch {
            print("❌ Error: \(error)")
            return []
        }
    }

    func generateEmbeddings(from pixelBuffers: [CVPixelBuffer]) async -> [[Float]] {
        var results: [[Float]] = []
        
        for pixelBuffer in pixelBuffers {
            let embedding = await generateEmbedding(from: pixelBuffer)
            results.append(embedding)
        }
        
        return results
    }

    func textToEmbedding(text: String) async -> [Float] {
        do {
            guard let tokenizer = tokenizer else {
                print("❌ Токенизатор не загружен")
                return []
            }

            guard let model = mobileClipTextModel else {
                print("❌ Text model not loaded")
                return []
            }

            let inputIds = tokenizer.encode_full(text: text)
                
            let inputArray = try MLMultiArray(shape: [1, 77], dataType: .int32)

            for (index, element) in inputIds.enumerated() {
                inputArray[index] = NSNumber(value: element)
            }

            let output = try model.prediction(text: inputArray).final_emb_1
            
            let count = output.count
            var result = [Float](repeating: 0, count: count)

            for i in 0..<count {
                result[i] = Float(truncating: output[i])
            }

            return result
        } catch {
            print(error.localizedDescription)
            return []
        }
    }
    
    /// Вычисляет косинусное сходство между двумя эмбедингами
    /// Возвращает значение от -1 до 1, где 1 означает полное сходство
    func cosineSimilarity(_ embedding1: [Float], _ embedding2: [Float]) -> Float {
        guard embedding1.count == embedding2.count else {
            print("❌ Embeddings must have the same dimension")
            return 0.0
        }
        
        var dotProduct: Float = 0.0
        var norm1: Float = 0.0
        var norm2: Float = 0.0
        
        for i in 0..<embedding1.count {
            dotProduct += embedding1[i] * embedding2[i]
            norm1 += embedding1[i] * embedding1[i]
            norm2 += embedding2[i] * embedding2[i]
        }
        
        let magnitude = sqrt(norm1) * sqrt(norm2)
        guard magnitude > 0 else {
            return 0.0
        }
        
        return dotProduct / magnitude
    }
    
    /// Находит наиболее похожие фотографии по текстовому запросу
    func findSimilarPhotos(query: String, minSimilarity: Float = 0.14, photos: [Photo]) async -> [(Photo, Float)] {
        let queryEmbedding = await textToEmbedding(text: query)
        
        guard !queryEmbedding.isEmpty else {
            print("❌ Failed to generate query embedding")
            return []
        }
        
        var similarities: [(Photo, Float)] = []
        
        for photo in photos {
            let similarity = cosineSimilarity(queryEmbedding, photo.embedding)
            similarities.append((photo, similarity))
        }
        
        // Фильтруем по минимальному порогу сходства (14%) и сортируем по убыванию
        let filteredResults = similarities
            .filter { $0.1 >= minSimilarity }
            .sorted { $0.1 > $1.1 }
        
        // Возвращаем топ результатов (но не больше чем есть после фильтрации)
        return Array(filteredResults)
    }

    private func processSingleAsset(_ asset: PHAsset) async -> [Float]? {
        // Конвертируем ассет в CVPixelBuffer
        guard let pixelBuffer = await convertAssetToThumbnail(asset) else {
            print("❌ Не удалось создать CVPixelBuffer для ассета: \(asset.localIdentifier)")
            return nil
        }
        
        let embedding = await generateEmbedding(from: pixelBuffer)
        
        if embedding.isEmpty {
            print("❌ Не удалось сгенерировать эмбединг для ассета: \(asset.localIdentifier)")
            return nil
        }

        return embedding
    }

    private func convertMultiArrayToFloatArray(_ multiArray: MLMultiArray) -> [Float] {
        let count = multiArray.count
        var result = [Float](repeating: 0, count: count)
        
        for i in 0..<count {
            result[i] = Float(truncating: multiArray[i])
        }
        
        return result
    }

    private func convertAssetToThumbnail(_ asset: PHAsset) async -> CVPixelBuffer? {
        return await withCheckedContinuation { continuation in
            let imageManager = PHImageManager.default()
            let requestOptions = PHImageRequestOptions()
            
            requestOptions.isSynchronous = false
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.resizeMode = .exact
            requestOptions.isNetworkAccessAllowed = false
            
            // Размер миниатюры для эмбедингов (MobileCLIP требует 256x256)
            let targetSize = CGSize(width: 256, height: 256)
            
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: requestOptions
            ) { image, info in
                guard let image = image,
                      let cgImage = image.cgImage else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // Проверяем размер изображения и создаем CVPixelBuffer точно 256x256
                print("🖼️ Исходное изображение: \(cgImage.width)x\(cgImage.height)")
                let pixelBuffer = self.cgImageToPixelBuffer(cgImage)
                if let buffer = pixelBuffer {
                    print("✅ CVPixelBuffer создан: \(CVPixelBufferGetWidth(buffer))x\(CVPixelBufferGetHeight(buffer))")
                }
                continuation.resume(returning: pixelBuffer)
            }
        }
    }
    
    private func cgImageToPixelBuffer(_ cgImage: CGImage) -> CVPixelBuffer? {
        // MobileCLIP требует точно 256x256
        let targetWidth = 256
        let targetHeight = 256
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            targetWidth,
            targetHeight,
            kCVPixelFormatType_32ARGB,
            nil,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        defer { CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0)) }
        
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: pixelData,
            width: targetWidth,
            height: targetHeight,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            return nil
        }
        
        // Рисуем изображение с масштабированием до точного размера 256x256
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))
        
        return buffer
    }
}