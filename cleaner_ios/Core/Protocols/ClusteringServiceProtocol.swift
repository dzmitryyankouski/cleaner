import Foundation

// MARK: - Clustering Service Protocol

/// Протокол для кластеризации эмбедингов
protocol ClusteringServiceProtocol {
    /// Группирует эмбединги по схожести
    /// - Parameters:
    ///   - embeddings: Массив эмбедингов для кластеризации
    ///   - threshold: Порог схожести (от 0 до 1)
    /// - Returns: Массив групп, где каждая группа содержит индексы похожих эмбедингов
    func groupEmbeddings(_ embeddings: [[Float]], threshold: Float) async -> [[Int]]
}

