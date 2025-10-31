import Foundation
import Photos

// MARK: - Photo Model

/// Модель фотографии с эмбедингом и метаданными
struct Photo: Identifiable, Equatable {
    let id: String
    let index: Int
    let asset: PHAsset
    let embedding: Embedding
    let fileSize: FileSize
    
    init(
        index: Int,
        asset: PHAsset,
        embedding: [Float],
        fileSize: Int64
    ) {
        self.id = asset.localIdentifier
        self.index = index
        self.asset = asset
        self.embedding = Embedding(values: embedding)
        self.fileSize = FileSize(bytes: fileSize)
    }
    
    static func == (lhs: Photo, rhs: Photo) -> Bool {
        lhs.id == rhs.id
    }
    
    /// Проверяет, является ли фото скриншотом
    func isScreenshot() -> Bool {
        asset.mediaSubtypes.contains(.photoScreenshot)
    }
}

// MARK: - Embedding Value Object

/// Value Object для хранения эмбединга
struct Embedding {
    let values: [Float]
    
    var isEmpty: Bool {
        values.isEmpty
    }
    
    var dimension: Int {
        values.count
    }
    
    init(values: [Float]) {
        self.values = values
    }
}

// MARK: - FileSize Value Object

/// Value Object для работы с размером файла
struct FileSize {
    let bytes: Int64
    
    init(bytes: Int64) {
        self.bytes = max(0, bytes)
    }
    
    /// Форматированная строка размера файла
    var formatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

