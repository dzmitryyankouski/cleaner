import Foundation

struct FileSize {
    let bytes: Int64
    
    init(bytes: Int64) {
        self.bytes = max(0, bytes)
    }
    
    var formatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
