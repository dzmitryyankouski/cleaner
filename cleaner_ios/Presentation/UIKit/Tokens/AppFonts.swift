import SwiftUI

// MARK: - All text styles in one place.

enum AppFonts {

    // MARK: - Button
    static let button = Font.custom("Geologica", size: 16).weight(.semibold)

    // MARK: - SectionHeader
    static let sectionHeaderTitle    = Font.custom("Geologica", size: 28).weight(.medium)
    static let sectionHeaderSubtitle = Font.custom("Geologica", size: 14).weight(.light)

    // MARK: - ProgressBar
    /// Geologica 20pt / Medium (500) — label + value text
    static let progressBarLabel = Font.custom("Geologica", size: 20).weight(.medium)

    // MARK: - Fallbacks (system)
    /// Section title — 20 bold
    static let title   = Font.system(size: 20, weight: .bold)
    /// Body text — 14 regular
    static let body    = Font.system(size: 14, weight: .regular)
    /// Small caption — 12 regular
    static let caption = Font.system(size: 12, weight: .regular)
}
