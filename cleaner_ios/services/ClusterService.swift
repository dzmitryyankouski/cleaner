struct ClusterImageGroup {
    let images: [Int]
    let averageSimilarity: Float
}

class ClusterService {

    func getImageGroups(for embeddings: [[Float]]) async -> [ClusterImageGroup] {
        guard !embeddings.isEmpty else { return [] }

        return []
    }
}
