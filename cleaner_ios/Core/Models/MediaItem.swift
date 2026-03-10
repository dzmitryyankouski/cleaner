import Foundation

enum MediaItem: Identifiable, Equatable, Hashable {
    case photo(PhotoModel)
    case video(VideoModel)

    var id: String {
        switch self {
        case .photo(let p): return p.id
        case .video(let v): return v.id
        }
    }

    var creationDate: Date? {
        switch self {
        case .photo(let p): return p.creationDate
        case .video(let v): return v.creationDate
        }
    }

    static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
        switch (lhs, rhs) {
        case (.photo(let l), .photo(let r)):
            return l.id == r.id
        case (.video(let l), .video(let r)):
            return l.id == r.id
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .photo(let p):
            hasher.combine("photo")
            hasher.combine(p.id)
        case .video(let v):
            hasher.combine("video")
            hasher.combine(v.id)
        }
    }
}
