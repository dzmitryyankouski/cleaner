import Foundation

// MARK: - Media Group

/// Универсальная группа медиа-элементов (фото или видео)
struct MediaGroup<T: Identifiable> {
    let items: [T]
    
    var count: Int {
        items.count
    }
    
    var isEmpty: Bool {
        items.isEmpty
    }
    
    init(items: [T]) {
        self.items = items
    }
}

// MARK: - Search Result

/// Результат поиска с оценкой релевантности
struct SearchResult<T> {
    let item: T
    let similarity: Float
    
    init(item: T, similarity: Float) {
        self.item = item
        self.similarity = similarity
    }
}

