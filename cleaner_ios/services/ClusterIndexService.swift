import Foundation
import Combine

/// Сервис для управления кластеризованным индексом эмбеддингов
class ClusterIndexService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var clusters: [Cluster] = []
    @Published var indexedEmbeddings: [IndexedEmbedding] = []
    @Published var clusteringStats: ClusteringStats?
    @Published var isClustering = false
    @Published var lastClusteringDate: Date?
    
    // MARK: - Private Properties
    
    private var clusteringConfig: ClusteringConfig = .default
    private var searchCache: [String: [SimilarityResult]] = [:]
    private let cacheExpirationTime: TimeInterval = 300 // 5 минут
    
    // MARK: - Initialization
    
    init() {
        print("🔍 ClusterIndexService инициализирован")
    }
    
    // MARK: - Public Methods
    
    /// Добавляет новые эмбеддинги и пересчитывает кластеры
    func addEmbeddings(_ embeddings: [[Float]], imageIndices: [Int]) async {
        guard !embeddings.isEmpty else { return }
        
        print("📥 Добавляем \(embeddings.count) новых эмбеддингов...")
        
        // Создаем индексированные эмбеддинги
        let newIndexedEmbeddings = zip(embeddings, imageIndices).map { embedding, imageIndex in
            IndexedEmbedding(embedding: embedding, imageIndex: imageIndex)
        }
        
        await MainActor.run {
            self.indexedEmbeddings.append(contentsOf: newIndexedEmbeddings)
        }
        
        // Пересчитываем кластеры
        await performClustering()
    }
    
    /// Выполняет кластеризацию всех эмбеддингов
    func performClustering() async {
        guard !indexedEmbeddings.isEmpty else {
            print("⚠️ Нет эмбеддингов для кластеризации")
            return
        }
        
        await MainActor.run {
            self.isClustering = true
        }
        
        print("🔄 Начинаем кластеризацию \(indexedEmbeddings.count) эмбеддингов...")
        
        let newClusters = await Task.detached {
            KMeansClustering.clusterEmbeddings(self.indexedEmbeddings, config: self.clusteringConfig)
        }.value
        
        await MainActor.run {
            self.clusters = newClusters
            self.isClustering = false
            self.lastClusteringDate = Date()
            self.clusteringStats = ClusteringStats(
                totalEmbeddings: self.indexedEmbeddings.count,
                clusters: newClusters,
                clusteringTime: 0 // Время будет вычислено в KMeansClustering
            )
            
            // Очищаем кэш поиска при обновлении кластеров
            self.searchCache.removeAll()
            
            print("✅ Кластеризация завершена. Создано \(newClusters.count) кластеров")
        }
    }
    
    /// Находит похожие эмбеддинги используя кластеризованный индекс
    func findSimilarEmbeddings(to queryEmbedding: [Float], 
                              maxResults: Int = 10, 
                              similarityThreshold: Float = 0.5) -> [SimilarityResult] {
        
        guard !clusters.isEmpty else {
            print("⚠️ Кластеры не инициализированы")
            return findSimilarEmbeddingsBruteForce(queryEmbedding, maxResults: maxResults, similarityThreshold: similarityThreshold)
        }
        
        // Проверяем кэш
        let cacheKey = "\(queryEmbedding.hashValue)_\(maxResults)_\(similarityThreshold)"
        if let cachedResults = searchCache[cacheKey],
           Date().timeIntervalSince(lastClusteringDate ?? Date.distantPast) < cacheExpirationTime {
            print("🎯 Используем кэшированные результаты поиска")
            return Array(cachedResults.prefix(maxResults))
        }
        
        print("🔍 Поиск похожих эмбеддингов в \(clusters.count) кластерах...")
        
        // Находим ближайший кластер
        let nearestCluster = findNearestCluster(queryEmbedding)
        
        // Ищем в ближайшем кластере и соседних
        var candidates: [SimilarityResult] = []
        
        // Добавляем результаты из ближайшего кластера
        candidates.append(contentsOf: searchInCluster(nearestCluster, queryEmbedding: queryEmbedding, similarityThreshold: similarityThreshold))
        
        // Добавляем результаты из соседних кластеров (опционально)
        let neighborClusters = findNeighborClusters(nearestCluster, queryEmbedding: queryEmbedding, maxNeighbors: 2)
        for cluster in neighborClusters {
            candidates.append(contentsOf: searchInCluster(cluster, queryEmbedding: queryEmbedding, similarityThreshold: similarityThreshold))
        }
        
        // Сортируем по сходству и ограничиваем количество результатов
        let results = candidates
            .sorted { $0.similarity > $1.similarity }
            .prefix(maxResults)
            .map { $0 }
        
        // Сохраняем в кэш
        searchCache[cacheKey] = Array(results)
        
        print("✅ Найдено \(results.count) похожих эмбеддингов")
        return Array(results)
    }
    
    /// Находит похожие эмбеддинги полным перебором (fallback)
    private func findSimilarEmbeddingsBruteForce(_ queryEmbedding: [Float], 
                                               maxResults: Int, 
                                               similarityThreshold: Float) -> [SimilarityResult] {
        print("🔍 Выполняем поиск полным перебором...")
        
        var results: [SimilarityResult] = []
        
        for embedding in indexedEmbeddings {
            let similarity = KMeansClustering.calculateCosineSimilarity(queryEmbedding, embedding.embedding)
            if similarity >= similarityThreshold {
                results.append(SimilarityResult(embedding: embedding, similarity: similarity, clusterId: embedding.clusterId))
            }
        }
        
        return results
            .sorted { $0.similarity > $1.similarity }
            .prefix(maxResults)
            .map { $0 }
    }
    
    /// Находит ближайший кластер к запросу
    private func findNearestCluster(_ queryEmbedding: [Float]) -> Cluster {
        var minDistance = Float.greatestFiniteMagnitude
        var nearestCluster = clusters[0]
        
        for cluster in clusters {
            let distance = calculateEuclideanDistance(queryEmbedding, cluster.centroid)
            if distance < minDistance {
                minDistance = distance
                nearestCluster = cluster
            }
        }
        
        return nearestCluster
    }
    
    /// Находит соседние кластеры
    private func findNeighborClusters(_ referenceCluster: Cluster, 
                                    queryEmbedding: [Float], 
                                    maxNeighbors: Int) -> [Cluster] {
        var clusterDistances: [(Cluster, Float)] = []
        
        for cluster in clusters {
            if cluster.id != referenceCluster.id {
                let distance = calculateEuclideanDistance(queryEmbedding, cluster.centroid)
                clusterDistances.append((cluster, distance))
            }
        }
        
        return clusterDistances
            .sorted { $0.1 < $1.1 }
            .prefix(maxNeighbors)
            .map { $0.0 }
    }
    
    /// Ищет похожие эмбеддинги в конкретном кластере
    private func searchInCluster(_ cluster: Cluster, 
                               queryEmbedding: [Float], 
                               similarityThreshold: Float) -> [SimilarityResult] {
        var results: [SimilarityResult] = []
        
        for embedding in cluster.embeddings {
            let similarity = KMeansClustering.calculateCosineSimilarity(queryEmbedding, embedding.embedding)
            if similarity >= similarityThreshold {
                results.append(SimilarityResult(embedding: embedding, similarity: similarity, clusterId: cluster.id))
            }
        }
        
        return results
    }
    
    /// Вычисляет евклидово расстояние между двумя векторами
    private func calculateEuclideanDistance(_ vector1: [Float], _ vector2: [Float]) -> Float {
        guard vector1.count == vector2.count else { return Float.greatestFiniteMagnitude }
        
        var sum: Float = 0
        for i in 0..<vector1.count {
            let diff = vector1[i] - vector2[i]
            sum += diff * diff
        }
        
        return sqrt(sum)
    }
    
    /// Обновляет конфигурацию кластеризации
    func updateClusteringConfig(_ config: ClusteringConfig) {
        clusteringConfig = config
        print("⚙️ Конфигурация кластеризации обновлена: k=\(config.k), maxIterations=\(config.maxIterations)")
    }
    
    /// Очищает все данные
    func clearAll() {
        clusters = []
        indexedEmbeddings = []
        clusteringStats = nil
        lastClusteringDate = nil
        searchCache.removeAll()
        print("🗑️ Все данные кластеризации очищены")
    }
    
    /// Получает статистику кластеризации
    func getClusteringStats() -> ClusteringStats? {
        return clusteringStats
    }
    
    /// Получает количество кластеров
    func getClusterCount() -> Int {
        return clusters.count
    }
    
    /// Получает общее количество индексированных эмбеддингов
    func getTotalEmbeddingsCount() -> Int {
        return indexedEmbeddings.count
    }
    
    /// Получает группы похожих изображений, сгруппированные по кластерам
    func getImageGroups(for queryEmbedding: [Float], similarityThreshold: Float = 0.5) -> [ImageGroup] {
        guard !clusters.isEmpty else {
            print("⚠️ Кластеры не инициализированы")
            return []
        }
        
        print("🔍 Группируем похожие изображения для запроса...")
        
        var groups: [ImageGroup] = []
        
        // Находим ближайший кластер
        let nearestCluster = findNearestCluster(queryEmbedding)
        
        // Создаем группу для ближайшего кластера
        let nearestGroupResults = searchInCluster(nearestCluster, queryEmbedding: queryEmbedding, similarityThreshold: similarityThreshold)
        if !nearestGroupResults.isEmpty {
            let averageSimilarity = nearestGroupResults.map { $0.similarity }.reduce(0, +) / Float(nearestGroupResults.count)
            let group = ImageGroup(
                id: nearestCluster.id,
                title: "Кластер \(clusters.firstIndex(where: { $0.id == nearestCluster.id }) ?? 0) + 1",
                images: nearestGroupResults,
                averageSimilarity: averageSimilarity,
                clusterId: nearestCluster.id
            )
            groups.append(group)
        }
        
        // Добавляем группы из соседних кластеров
        let neighborClusters = findNeighborClusters(nearestCluster, queryEmbedding: queryEmbedding, maxNeighbors: 2)
        for (index, cluster) in neighborClusters.enumerated() {
            let clusterResults = searchInCluster(cluster, queryEmbedding: queryEmbedding, similarityThreshold: similarityThreshold)
            if !clusterResults.isEmpty {
                let averageSimilarity = clusterResults.map { $0.similarity }.reduce(0, +) / Float(clusterResults.count)
                let group = ImageGroup(
                    id: cluster.id,
                    title: "Соседний кластер \(index + 1)",
                    images: clusterResults,
                    averageSimilarity: averageSimilarity,
                    clusterId: cluster.id
                )
                groups.append(group)
            }
        }
        
        // Сортируем группы по среднему сходству
        groups.sort { $0.averageSimilarity > $1.averageSimilarity }
        
        print("✅ Создано \(groups.count) групп изображений")
        return groups
    }
}
