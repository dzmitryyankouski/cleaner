import Foundation
import Vision
import CoreML
import UIKit

class ImageEmbeddingService {
    private var mobileClipModel: MLModel?
    
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

    func generateEmbedding(from image: UIImage) -> [Float] {
        guard let mobileClipModel = mobileClipModel else {
            print("❌ Model not loaded")
            return []
        }

        guard let cgImage = image.cgImage else {
            print("❌ Error getting cgImage")
            return []
        }

        var result: [Float] = []
        let semaphore = DispatchSemaphore(value: 0)

        let request = VNCoreMLRequest(model: try! VNCoreMLModel(for: mobileClipModel)) { request, error in
             DispatchQueue.main.async {
                
                if let error = error {
                    print("❌ Error: \(error)")
                    semaphore.signal()
                    return
                }
                
                guard let results = request.results as? [VNCoreMLFeatureValueObservation],
                      let firstResult = results.first,
                      let multiArray = firstResult.featureValue.multiArrayValue else {
                    print("❌ Error getting embedding")
                    semaphore.signal()
                    return
                }
                
                result = self.convertMultiArrayToFloatArray(multiArray)
                semaphore.signal()
            }
        }
        
        request.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("❌ Error: \(error)")
                semaphore.signal()
            }
        }
        
        semaphore.wait()
        return result
    }

    func generateEmbeddings(from images: [UIImage]) async -> [[Float]] {
        var results: [[Float]] = []
        
        for image in images {
            let embedding = generateEmbedding(from: image)
            results.append(embedding)
        }
        
        return results
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