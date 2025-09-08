import Foundation
@preconcurrency import Vision
import CoreML
import UIKit
import Photos
import NaturalLanguage

struct Photo {
    let asset: PHAsset
    let embedding: [Float]
}

class ImageEmbeddingService {
    private var mobileClipImageModel: MLModel?
    private var mobileClipTextModel: mobileclip_s0_text?
    private var concurrentTasks = 5

    var processedPhotos: [Photo] = []
    var tokenizer: CLIPTokenizer?
    
    // Callback для уведомления об обновлениях
    var onPhotoProcessed: ((Photo) -> Void)?
    var onIndexingComplete: (() -> Void)?
    
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
        if let modelURL = Bundle.main.url(forResource: "mobileclip_s0_image", withExtension: "mlmodelc") {
            do {
                mobileClipImageModel = try MLModel(contentsOf: modelURL)
                print("✅ Модель изображений MobileCLIP загружена из Bundle!")
                return
            } catch {
                print("❌ Ошибка загрузки модели изображений из Bundle: \(error)")
            }
        }
    }
    
    private func loadTextModel() {
        do {
            mobileClipTextModel = try mobileclip_s0_text()
            print("Model loaded")
        } catch {
            print("❌ Ошибка загрузки модели текста из Bundle: \(error)")
        }
    }

    func indexPhotos(photos: [PHAsset]) async {
        print("🔄 Начинаем индексацию \(photos.count) фотографий...")
        
        // Обрабатываем каждый ассет в отдельной таске с ограничением
        await withTaskGroup(of: Photo?.self) { group in
            var activeTasks = 0
            
            for asset in photos {
                // Ждем, пока освободится место для новой таски
                while activeTasks >= concurrentTasks {
                    if let result = await group.next() {
                        if let photo = result {
                            self.processedPhotos.append(photo)
                            // Уведомляем о новой обработанной фотографии
                            await MainActor.run {
                                self.onPhotoProcessed?(photo)
                            }
                        }
                        activeTasks -= 1
                    }
                }
                
                group.addTask {
                    await self.processSingleAsset(asset)
                }
                activeTasks += 1
            }
            
            // Обрабатываем оставшиеся результаты
            for await result in group {
                if let photo = result {
                    // Обновляем UI в реальном времени
                    await MainActor.run {
                        self.processedPhotos.append(photo)
                        // Уведомляем о новой обработанной фотографии
                        self.onPhotoProcessed?(photo)
                    }
                }
            }
        }
        
        // Уведомляем о завершении индексации
        await MainActor.run {
            self.onIndexingComplete?()
        }
    }

    func generateEmbedding(from image: UIImage) async -> [Float] {
        guard let mobileClipImageModel = mobileClipImageModel else {
            print("❌ Image model not loaded")
            return []
        }

        guard let cgImage = image.cgImage else {
            print("❌ Error getting cgImage")
            return []
        }

        return await withCheckedContinuation { continuation in
            let request = VNCoreMLRequest(model: try! VNCoreMLModel(for: mobileClipImageModel)) { request, error in
                if let error = error {
                    print("❌ Error: \(error)")
                    continuation.resume(returning: [])
                    return
                }
                
                guard let results = request.results as? [VNCoreMLFeatureValueObservation],
                      let firstResult = results.first,
                      let multiArray = firstResult.featureValue.multiArrayValue else {
                    print("❌ Error getting embedding")
                    continuation.resume(returning: [])
                    return
                }
                
                let result = self.convertMultiArrayToFloatArray(multiArray)
                continuation.resume(returning: result)
            }
            
            request.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    print("❌ Error: \(error)")
                    continuation.resume(returning: [])
                }
            }
        }
    }

    func generateEmbeddings(from images: [UIImage]) async -> [[Float]] {
        var results: [[Float]] = []
        
        for image in images {
            let embedding = await generateEmbedding(from: image)
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
    func findSimilarPhotos(query: String, limit: Int = 10) async -> [(Photo, Float)] {
        let queryEmbedding = await textToEmbedding(text: query)
        
        guard !queryEmbedding.isEmpty else {
            print("❌ Failed to generate query embedding")
            return []
        }
        
        var similarities: [(Photo, Float)] = []
        
        for photo in processedPhotos {
            let similarity = cosineSimilarity(queryEmbedding, photo.embedding)
            similarities.append((photo, similarity))
        }
        
        // Сортируем по убыванию сходства и возвращаем топ результатов
        return similarities.sorted { $0.1 > $1.1 }.prefix(limit).map { $0 }
    }

    private func processSingleAsset(_ asset: PHAsset) async -> Photo? {
        // Конвертируем ассет в миниатюру
        guard let thumbnail = await convertAssetToThumbnail(asset) else {
            print("❌ Не удалось создать миниатюру для ассета: \(asset.localIdentifier)")
            return nil
        }
        
        let embedding = await generateEmbedding(from: thumbnail)
        
        if embedding.isEmpty {
            print("❌ Не удалось сгенерировать эмбединг для ассета: \(asset.localIdentifier)")
            return nil
        }
        
        return Photo(asset: asset, embedding: embedding)
    }

    private func convertMultiArrayToFloatArray(_ multiArray: MLMultiArray) -> [Float] {
        let count = multiArray.count
        var result = [Float](repeating: 0, count: count)
        
        for i in 0..<count {
            result[i] = Float(truncating: multiArray[i])
        }
        
        return result
    }

    private func convertAssetToThumbnail(_ asset: PHAsset) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let imageManager = PHImageManager.default()
            let requestOptions = PHImageRequestOptions()
            
            requestOptions.isSynchronous = false
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.resizeMode = .exact
            requestOptions.isNetworkAccessAllowed = false
            
            // Размер миниатюры для эмбедингов (можно настроить)
            let targetSize = CGSize(width: 224, height: 224)
            
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: requestOptions
            ) { image, info in
                continuation.resume(returning: image)
            }
        }
    }
}