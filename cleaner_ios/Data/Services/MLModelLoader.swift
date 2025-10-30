import Foundation
import CoreML

// MARK: - ML Model Loader

/// Загрузчик машинных моделей
final class MLModelLoader {
    
    // MARK: - Model Types
    
    enum ModelType {
        case imageS0, imageS1, imageS2
        case textS0, textS1, textS2
        
        var description: String {
            switch self {
            case .imageS0: return "mobileclip_s0_image"
            case .imageS1: return "mobileclip_s1_image"
            case .imageS2: return "mobileclip_s2_image"
            case .textS0: return "mobileclip_s0_text"
            case .textS1: return "mobileclip_s1_text"
            case .textS2: return "mobileclip_s2_text"
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Загружает модель для изображений (s2 по умолчанию)
    func loadImageModel() -> Result<Any, EmbeddingError> {
        do {
            let model = try mobileclip_s2_image()
            return .success(model)
        } catch {
            return .failure(.modelNotLoaded("image model"))
        }
    }
    
    /// Загружает модель для текста (s2 по умолчанию)
    func loadTextModel() -> Result<Any, EmbeddingError> {
        do {
            let model = try mobileclip_s2_text()
            return .success(model)
        } catch {
            return .failure(.modelNotLoaded("text model"))
        }
    }
}

