import Foundation
import Accelerate

// ==================== DSU (Union-Find) ====================
final class UnionFind {
    private var parent: [Int]
    private var rank: [UInt8]

    init(_ n: Int) {
        parent = Array(0..<n)
        rank = .init(repeating: 0, count: n)
    }

    func find(_ x: Int) -> Int {
        var x = x
        while parent[x] != x {
            parent[x] = parent[parent[x]]
            x = parent[x]
        }
        return x
    }

    func union(_ a: Int, _ b: Int) {
        var ra = find(a), rb = find(b)
        if ra == rb { return }
        if rank[ra] < rank[rb] { swap(&ra, &rb) }
        parent[rb] = ra
        if rank[ra] == rank[rb] { rank[ra] &+= 1 }
    }

    func groups() -> [[Int]] {
        var buckets: [Int: [Int]] = [:]
        for i in 0..<parent.count {
            buckets[find(i), default: []].append(i)
        }
        return Array(buckets.values)
    }
}

// ==================== УТИЛИТЫ ВЕКТОРОВ ====================
@inline(__always)
func l2Normalize(_ x: inout [Float]) {
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
func dot(_ a: [Float], _ b: [Float]) -> Float {
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

// ==================== LSH (Random Hyperplane) ====================
struct RNG: RandomNumberGenerator {
    var state: UInt64

    init(_ seed: UInt64) { self.state = seed }

    mutating func next() -> UInt64 {
        // xorshift64*
        var x = state
        x &+= 0x9E3779B97F4A7C15
        x = (x ^ (x >> 30)) &* 0xBF58476D1CE4E5B9
        x = (x ^ (x >> 27)) &* 0x94D049BB133111EB
        x = x ^ (x >> 31)
        state = x
        return x
    }

    mutating func nextFloat() -> Float {
        let v = next() >> 11 // 53 бита
        return Float(Double(v) / Double(1 << 53))
    }
}

struct LSHTable {
    // Матрица гиперплоскостей: planesPerTable x dim
    var planes: [[Float]] // каждая плоскость — вектор длины dim

    init(dim: Int, planes: Int, rng: inout RNG) {
        self.planes = (0..<planes).map { _ in
            var v = (0..<dim).map { _ in
                // нормальное приближение через Box-Muller или просто U(-1,1)
                2 * rng.nextFloat() - 1
            }
            l2Normalize(&v)
            return v
        }
    }

    @inline(__always)
    func hash(_ v: [Float]) -> UInt64 {
        precondition(planes.count <= 64, "planesPerTable must be <= 64 for UInt64 key")
        var key: UInt64 = 0

        for (i, p) in planes.enumerated() {
            if dot(v, p) >= 0 { key |= (1 << UInt64(i)) }
        }

        return key
    }
}

struct LSH {
    let tables: [LSHTable]

    init(numTables: Int, planesPerTable: Int, dim: Int, seed: UInt64) {
        var rng = RNG(seed)
        self.tables = (0..<numTables).map { _ in
            LSHTable(dim: dim, planes: planesPerTable, rng: &rng)
        }
    }

    func hashAll(_ vectors: [[Float]]) -> [[UInt64]] {
        vectors.map { v in tables.map { $0.hash(v) } }
    }
}

class ClusterService {
    var numTables: Int = 10
    var planesPerTable: Int = 10
    var seed: UInt64 = 42

    func getImageGroups(for embeddings: [[Float]], threshold: Float = 0.85) async -> [[Int]] {
        guard !embeddings.isEmpty else { return [] }

        let n = embeddings.count
        precondition(n > 0, "Нет эмбеддингов")
        let dim = embeddings[0].count
        precondition(embeddings.allSatisfy { $0.count == dim }, "Размерности векторов отличаются")

        // 1) Нормализация (для косинуса)
        var X = embeddings
        for i in 0..<n { var v = X[i]; l2Normalize(&v); X[i] = v }

        // 2) LSH
        let lsh = LSH(numTables: numTables, planesPerTable: planesPerTable, dim: dim, seed: seed)
        let hashesPerVector = lsh.hashAll(X) // [i][t] -> UInt64

        // 3) Бакеты по каждой таблице
        var bucketsByTable: [Int: [UInt64: [Int]]] = [:]
        for t in 0..<numTables {
            var buckets: [UInt64: [Int]] = [:]
            for i in 0..<n {
                let h = hashesPerVector[i][t]
                buckets[h, default: []].append(i)
            }
            bucketsByTable[t] = buckets
        }

        // 4) Генерация кандидатов и DSU
        let dsu = UnionFind(n)
        var seenPairs = Set<UInt64>() // компактно кодируем пары (i<j) в 64 бита
        seenPairs.reserveCapacity(n * 4)

        @inline(__always)
        func pairKey(_ i: Int, _ j: Int) -> UInt64 {
            let a = UInt32(min(i,j))
            let b = UInt32(max(i,j))
            return (UInt64(a) << 32) | UInt64(b)
        }

        func considerBucket(_ items: [Int]) {
            let m = items.count
            if m < 2 { return }
            let maxBucket = 1000 // максимальный размер бакета
            if m > maxBucket { return } // пропускаем сверх-гигантов; можно поднять порог
            // Полное сравнение внутри бакета
            for ii in 0..<(m-1) {
                let i = items[ii]
                let vi = X[i]
                for jj in (ii+1)..<m {
                    let j = items[jj]
                    let key = pairKey(i, j)
                    if seenPairs.contains(key) { continue }
                    seenPairs.insert(key)

                    let sim = dot(vi, X[j]) // cos, т.к. нормировано
                    if sim >= threshold {
                        dsu.union(i, j)
                    }
                }
            }
        }

        for t in 0..<numTables {
            guard let buckets = bucketsByTable[t] else { continue }
            for (_, items) in buckets {
                considerBucket(items)
            }
        }

        return dsu.groups()
    }

    
}
