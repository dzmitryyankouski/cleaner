import Foundation
import Vision
import CoreML
import UIKit

class ImageEmbeddingService: ObservableObject {
    private var mobileClipModel: MLModel?
    
    @Published var embedding: [Float] = []

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

    func generateEmbedding(from image: UIImage) {
        guard let mobileClipModel = mobileClipModel else {
            print("❌ Model not loaded")
            return
        }

        guard let cgImage = image.cgImage else {
            print("❌ Error getting cgImage")
            return
        }

        let request = VNCoreMLRequest(model: try! VNCoreMLModel(for: mobileClipModel)) { request, error in
             DispatchQueue.main.async {
                
                if let error = error {
                    print("❌ Error: \(error)")
                    return
                }
                
                guard let results = request.results as? [VNCoreMLFeatureValueObservation],
                      let firstResult = results.first,
                      let multiArray = firstResult.featureValue.multiArrayValue else {
                    print("❌ Error getting embedding")
                    return
                }
                
                self.embedding = self.convertMultiArrayToFloatArray(multiArray)
                print("✅ Embedding generated: \(self.embedding)")
            }
        }
        
        request.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("❌ Error: \(error)")
            }
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