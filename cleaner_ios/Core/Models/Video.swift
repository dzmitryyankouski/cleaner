import Foundation
import Photos

// MARK: - Video Model

/// Модель видео с эмбедингом и метаданными
struct Video: Identifiable, Equatable {
    let id: String
    let asset: PHAsset
    let duration: Duration
    let fileSize: FileSize
    let creationDate: Date?
    let modificationDate: Date?
    let embedding: Embedding
    
    init(
        asset: PHAsset,
        duration: TimeInterval,
        fileSize: Int64,
        creationDate: Date?,
        modificationDate: Date?,
        embedding: [Float]
    ) {
        self.id = asset.localIdentifier
        self.asset = asset
        self.duration = Duration(seconds: duration)
        self.fileSize = FileSize(bytes: fileSize)
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        self.embedding = Embedding(values: embedding)
    }
    
    static func == (lhs: Video, rhs: Video) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Duration Value Object

/// Value Object для работы с длительностью видео
struct Duration {
    let seconds: TimeInterval
    
    init(seconds: TimeInterval) {
        self.seconds = max(0, seconds)
    }
    
    /// Форматированная строка длительности
    var formatted: String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) % 3600 / 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

