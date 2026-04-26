import SwiftUI

/// Named colors for every storage-report sub-item and badge.
/// Use these instead of raw hex strings so the donut chart, legend dots,
/// and any other UI always stay in sync.
enum StorageReportPalette {

    // MARK: - Photos sub-items
    static let blurryPhotos    = Color(hex: "#6600FF")
    static let similarPhotos   = Color(hex: "#CC00FF")
    static let duplicates      = Color(hex: "#FF9500")
    static let screenshots     = Color(hex: "#0099FF")
    static let livePhotos      = Color(hex: "#00C07A")

    // MARK: - Videos sub-items
    static let similarVideos   = Color(hex: "#A6C700")
    static let screenRecords   = Color(hex: "#FF0073")

    // MARK: - Category badges
    static let photosBadge     = Color(hex: "#4524FF")
    static let videosBadge     = Color(hex: "#4524FF")
    static let otherBadge      = Color(hex: "#A3A9DB")
}

