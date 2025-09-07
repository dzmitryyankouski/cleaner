import Foundation

/// Реализация алгоритма K-Means для кластеризации эмбеддингов
class KMeansClustering {
    
    // MARK: - Публичные методы
    
    /// Кластеризует эмбеддинги с помощью алгоритма K-Means
    static func clusterEmbeddings(_ embeddings: [IndexedEmbedding], config: ClusteringConfig = .default) -> [Cluster] {
        guard !embeddings.isEmpty else { return [] }
        guard embeddings.count >= config.k else {
            // Если эмбеддингов меньше чем кластеров, создаем по одному кластеру на эмбеддинг
            return createSingleEmbeddingClusters(embeddings)
        }
        
        let startTime = Date()
        print("🔄 Начинаем кластеризацию \(embeddings.count) эмбеддингов на \(config.k) кластеров...")
        
        // Инициализация центроидов случайным образом
        var centroids = initializeCentroids(embeddings, k: config.k)
        var clusters: [Cluster] = []
        var previousCentroids: [[Float]] = []
        var iteration = 0
        
        repeat {
            iteration += 1
            previousCentroids = centroids.map { $0 }
            
            // Назначение эмбеддингов к ближайшим центроидам
            clusters = assignEmbeddingsToClusters(embeddings, centroids: centroids)
            
            // Обновление центроидов
            centroids = updateCentroids(clusters)
            
            // Проверка сходимости
            let converged = checkConvergence(previousCentroids, centroids, threshold: config.convergenceThreshold)
            
            print("🔄 Итерация \(iteration): создано \(clusters.count) кластеров")
            
            if converged || iteration >= config.maxIterations {
                break
            }
            
        } while true
        
        let clusteringTime = Date().timeIntervalSince(startTime)
        print("✅ Кластеризация завершена за \(String(format: "%.2f", clusteringTime)) секунд")
        print("📊 Статистика: \(ClusteringStats(totalEmbeddings: embeddings.count, clusters: clusters, clusteringTime: clusteringTime))")
        
        return clusters
    }
    
    // MARK: - Приватные методы
    
    /// Создает кластеры для случаев, когда эмбеддингов меньше чем k
    private static func createSingleEmbeddingClusters(_ embeddings: [IndexedEmbedding]) -> [Cluster] {
        return embeddings.map { embedding in
            var cluster = Cluster(centroid: embedding.embedding)
            cluster.embeddings = [embedding]
            return cluster
        }
    }
    
    /// Инициализирует центроиды случайным образом
    private static func initializeCentroids(_ embeddings: [IndexedEmbedding], k: Int) -> [[Float]] {
        guard !embeddings.isEmpty else { return [] }
        
        let embeddingDimension = embeddings[0].embedding.count
        var centroids: [[Float]] = []
        
        // Выбираем k случайных эмбеддингов как начальные центроиды
        let shuffledEmbeddings = embeddings.shuffled()
        for i in 0..<min(k, shuffledEmbeddings.count) {
            centroids.append(shuffledEmbeddings[i].embedding)
        }
        
        return centroids
    }
    
    /// Назначает эмбеддинги к ближайшим центроидам
    private static func assignEmbeddingsToClusters(_ embeddings: [IndexedEmbedding], centroids: [[Float]]) -> [Cluster] {
        var clusters: [Cluster] = []
        
        // Создаем пустые кластеры
        for (index, centroid) in centroids.enumerated() {
            var cluster = Cluster(centroid: centroid)
            cluster.embeddings = []
            clusters.append(cluster)
        }
        
        // Назначаем каждый эмбеддинг к ближайшему центроиду
        for embedding in embeddings {
            let nearestCentroidIndex = findNearestCentroid(embedding.embedding, centroids: centroids)
            if nearestCentroidIndex < clusters.count {
                clusters[nearestCentroidIndex].embeddings.append(embedding)
            }
        }
        
        return clusters
    }
    
    /// Находит ближайший центроид для эмбеддинга
    private static func findNearestCentroid(_ embedding: [Float], centroids: [[Float]]) -> Int {
        var minDistance = Float.greatestFiniteMagnitude
        var nearestIndex = 0
        
        for (index, centroid) in centroids.enumerated() {
            let distance = calculateEuclideanDistance(embedding, centroid)
            if distance < minDistance {
                minDistance = distance
                nearestIndex = index
            }
        }
        
        return nearestIndex
    }
    
    /// Обновляет центроиды на основе эмбеддингов в кластерах
    private static func updateCentroids(_ clusters: [Cluster]) -> [[Float]] {
        return clusters.map { cluster in
            guard !cluster.embeddings.isEmpty else { return cluster.centroid }
            
            let embeddingDimension = cluster.embeddings[0].embedding.count
            var newCentroid = [Float](repeating: 0, count: embeddingDimension)
            
            // Вычисляем среднее арифметическое всех эмбеддингов в кластере
            for embedding in cluster.embeddings {
                for i in 0..<embeddingDimension {
                    newCentroid[i] += embedding.embedding[i]
                }
            }
            
            // Нормализуем на количество эмбеддингов
            let count = Float(cluster.embeddings.count)
            for i in 0..<embeddingDimension {
                newCentroid[i] /= count
            }
            
            return newCentroid
        }
    }
    
    /// Проверяет сходимость алгоритма
    private static func checkConvergence(_ previousCentroids: [[Float]], _ currentCentroids: [[Float]], threshold: Float) -> Bool {
        guard previousCentroids.count == currentCentroids.count else { return false }
        
        for (prev, curr) in zip(previousCentroids, currentCentroids) {
            let distance = calculateEuclideanDistance(prev, curr)
            if distance > threshold {
                return false
            }
        }
        
        return true
    }
    
    /// Вычисляет евклидово расстояние между двумя векторами
    private static func calculateEuclideanDistance(_ vector1: [Float], _ vector2: [Float]) -> Float {
        guard vector1.count == vector2.count else { return Float.greatestFiniteMagnitude }
        
        var sum: Float = 0
        for i in 0..<vector1.count {
            let diff = vector1[i] - vector2[i]
            sum += diff * diff
        }
        
        return sqrt(sum)
    }
    
    /// Вычисляет косинусное сходство между двумя векторами
    static func calculateCosineSimilarity(_ vector1: [Float], _ vector2: [Float]) -> Float {
        guard vector1.count == vector2.count else { return 0.0 }
        
        var dotProduct: Float = 0.0
        var norm1: Float = 0.0
        var norm2: Float = 0.0
        
        for i in 0..<vector1.count {
            dotProduct += vector1[i] * vector2[i]
            norm1 += vector1[i] * vector1[i]
            norm2 += vector2[i] * vector2[i]
        }
        
        let magnitude1 = sqrt(norm1)
        let magnitude2 = sqrt(norm2)
        
        guard magnitude1 > 0 && magnitude2 > 0 else { return 0.0 }
        
        return dotProduct / (magnitude1 * magnitude2)
    }
}
