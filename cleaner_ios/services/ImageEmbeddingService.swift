import Foundation
import Vision
import CoreML
import UIKit
import Photos

struct Photo {
    let asset: PHAsset
    let embedding: [Float]
}

class ImageEmbeddingService {
    private var mobileClipModel: MLModel?
    private var concurrentTasks = 5

    var processedPhotos: [Photo] = []
    
    // Callback для уведомления об обновлениях
    var onPhotoProcessed: ((Photo) -> Void)?
    var onIndexingComplete: (() -> Void)?
    
    init() {
        guard Bundle.main.url(forResource: "mobileclip_s0_image", withExtension: "mlmodelc") != nil else {
            print("❌ Model not found in Bundle")
            return
        }

        if let modelURL = Bundle.main.url(forResource: "mobileclip_s0_image", withExtension: "mlmodelc") {
            do {
                mobileClipModel = try MLModel(contentsOf: modelURL)
            } catch {
                print("❌ Error loading model from Bundle: \(error)")
            }
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
        guard let mobileClipModel = mobileClipModel else {
            print("❌ Model not loaded")
            return []
        }

        guard let cgImage = image.cgImage else {
            print("❌ Error getting cgImage")
            return []
        }

        return await withCheckedContinuation { continuation in
            let request = VNCoreMLRequest(model: try! VNCoreMLModel(for: mobileClipModel)) { request, error in
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

    private func processSingleAsset(_ asset: PHAsset) async -> Photo? {
        do {
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
            
        } catch {
            print("❌ Ошибка при обработке ассета \(asset.localIdentifier): \(error)")
            return nil
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