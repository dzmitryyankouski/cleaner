import Foundation

protocol ClusteringServiceProtocol {
    func groupEmbeddings(_ embeddings: [[Float]], threshold: Float) async -> [[Int]]
}
