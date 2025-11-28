import Foundation
import Accelerate

final class LSHClusteringService: ClusteringServiceProtocol {
    struct Configuration {
        let numTables: Int
        let planesPerTable: Int
        let seed: UInt64
        
        static let `default` = Configuration(
            numTables: 10,
            planesPerTable: 10,
            seed: 42
        )
    }
    
    private let configuration: Configuration
    
    init(configuration: Configuration = .default) {
        self.configuration = configuration
    }
    
    func groupEmbeddings(_ embeddings: [[Float]], threshold: Float) async -> [[Int]] {
        guard !embeddings.isEmpty else { return [] }
        
        let n = embeddings.count
        guard n > 0 else { return [] }
        
        let dim = embeddings[0].count
        guard embeddings.allSatisfy({ $0.count == dim }) else {
            print("⚠️ Embeddings dimensions mismatch")
            return []
        }
        
        var normalizedEmbeddings = embeddings
        for i in 0..<n {
            l2Normalize(&normalizedEmbeddings[i])
        }
        
        let lsh = LSH(
            numTables: configuration.numTables,
            planesPerTable: configuration.planesPerTable,
            dim: dim,
            seed: configuration.seed
        )
        let hashesPerVector = lsh.hashAll(normalizedEmbeddings)
        
        var bucketsByTable: [Int: [UInt64: [Int]]] = [:]
        for t in 0..<configuration.numTables {
            var buckets: [UInt64: [Int]] = [:]
            for i in 0..<n {
                let h = hashesPerVector[i][t]
                buckets[h, default: []].append(i)
            }
            bucketsByTable[t] = buckets
        }
        
        let dsu = UnionFind(n)
        var seenPairs = Set<UInt64>()
        seenPairs.reserveCapacity(n * 4)
        
        func pairKey(_ i: Int, _ j: Int) -> UInt64 {
            let a = UInt32(min(i, j))
            let b = UInt32(max(i, j))
            return (UInt64(a) << 32) | UInt64(b)
        }
        
        func considerBucket(_ items: [Int]) {
            let m = items.count
            guard m >= 2 && m <= 1000 else { return }
            
            for ii in 0..<(m-1) {
                let i = items[ii]
                let vi = normalizedEmbeddings[i]
                for jj in (ii+1)..<m {
                    let j = items[jj]
                    let key = pairKey(i, j)
                    guard !seenPairs.contains(key) else { continue }
                    seenPairs.insert(key)
                    
                    let sim = dot(vi, normalizedEmbeddings[j])
                    if sim >= threshold {
                        dsu.union(i, j)
                    }
                }
            }
        }
        
        for t in 0..<configuration.numTables {
            guard let buckets = bucketsByTable[t] else { continue }
            for (_, items) in buckets {
                considerBucket(items)
            }
        }
        
        return dsu.groups()
    }
    
    @inline(__always)
    private func l2Normalize(_ x: inout [Float]) {
        #if canImport(Accelerate)
        var sum: Float = 0
        vDSP_svesq(x, 1, &sum, vDSP_Length(x.count))
        let nrm = sqrtf(sum) + 1e-12
        var inv = 1.0 / nrm
        vDSP_vsmul(x, 1, &inv, &x, 1, vDSP_Length(x.count))
        #else
        let nrm = sqrt(max(1e-12, x.reduce(0) { $0 + $1*$1 }))
        for i in 0..<x.count { x[i] /= nrm }
        #endif
    }
    
    @inline(__always)
    private func dot(_ a: [Float], _ b: [Float]) -> Float {
        #if canImport(Accelerate)
        var result: Float = 0
        vDSP_dotpr(a, 1, b, 1, &result, vDSP_Length(a.count))
        return result
        #else
        var s: Float = 0
        for i in 0..<a.count { s += a[i] * b[i] }
        return s
        #endif
    }
}

private final class LSH {
    let numTables: Int
    let planesPerTable: Int
    let dim: Int
    var hyperplanes: [[[Float]]]
    
    init(numTables: Int, planesPerTable: Int, dim: Int, seed: UInt64) {
        self.numTables = numTables
        self.planesPerTable = planesPerTable
        self.dim = dim
        self.hyperplanes = []
        
        var rng = Xoshiro256StarStar(seed: seed)
        for _ in 0..<numTables {
            var table: [[Float]] = []
            for _ in 0..<planesPerTable {
                var plane = [Float](repeating: 0, count: dim)
                for i in 0..<dim {
                    plane[i] = rng.nextGaussian()
                }
                table.append(plane)
            }
            hyperplanes.append(table)
        }
    }
    
    func hashAll(_ vecs: [[Float]]) -> [[UInt64]] {
        var result: [[UInt64]] = []
        result.reserveCapacity(vecs.count)
        for v in vecs {
            result.append(hashVector(v))
        }
        return result
    }
    
    private func hashVector(_ v: [Float]) -> [UInt64] {
        var hashes: [UInt64] = []
        hashes.reserveCapacity(numTables)
        for t in 0..<numTables {
            let planes = hyperplanes[t]
            var bits: UInt64 = 0
            for (i, plane) in planes.enumerated() {
                let dotProduct = dot(v, plane)
                if dotProduct >= 0 {
                    bits |= (1 << i)
                }
            }
            hashes.append(bits)
        }
        return hashes
    }
    
    @inline(__always)
    private func dot(_ a: [Float], _ b: [Float]) -> Float {
        #if canImport(Accelerate)
        var result: Float = 0
        vDSP_dotpr(a, 1, b, 1, &result, vDSP_Length(a.count))
        return result
        #else
        var s: Float = 0
        for i in 0..<a.count { s += a[i] * b[i] }
        return s
        #endif
    }
}

private final class UnionFind {
    var parent: [Int]
    var rank: [Int]
    
    init(_ n: Int) {
        parent = Array(0..<n)
        rank = [Int](repeating: 0, count: n)
    }
    
    func find(_ x: Int) -> Int {
        if parent[x] != x {
            parent[x] = find(parent[x])
        }
        return parent[x]
    }
    
    func union(_ x: Int, _ y: Int) {
        let rx = find(x)
        let ry = find(y)
        if rx == ry { return }
        
        if rank[rx] < rank[ry] {
            parent[rx] = ry
        } else if rank[rx] > rank[ry] {
            parent[ry] = rx
        } else {
            parent[ry] = rx
            rank[rx] += 1
        }
    }
    
    func groups() -> [[Int]] {
        var groupsDict: [Int: [Int]] = [:]
        for i in 0..<parent.count {
            let root = find(i)
            groupsDict[root, default: []].append(i)
        }
        return Array(groupsDict.values).filter { $0.count > 1 }
    }
}

private struct Xoshiro256StarStar {
    private var state: (UInt64, UInt64, UInt64, UInt64)
    
    init(seed: UInt64) {
        state = (seed, seed &+ 1, seed &+ 2, seed &+ 3)
        for _ in 0..<20 { _ = next() }
    }
    
    mutating func next() -> UInt64 {
        let result = rotl(state.1 &* 5, 7) &* 9
        let t = state.1 << 17
        state.2 ^= state.0
        state.3 ^= state.1
        state.1 ^= state.2
        state.0 ^= state.3
        state.2 ^= t
        state.3 = rotl(state.3, 45)
        return result
    }
    
    mutating func nextGaussian() -> Float {
        let u1 = Float(next()) / Float(UInt64.max)
        let u2 = Float(next()) / Float(UInt64.max)
        return sqrtf(-2 * logf(u1 + 1e-12)) * cosf(2 * Float.pi * u2)
    }
    
    private func rotl(_ x: UInt64, _ k: Int) -> UInt64 {
        return (x << k) | (x >> (64 - k))
    }
}
