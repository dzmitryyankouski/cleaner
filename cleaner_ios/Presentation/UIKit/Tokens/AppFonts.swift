import SwiftUI

// MARK: - All text styles in one place.

enum AppFonts {
    /// Button label — 16 semibold
    static let button = Font.system(size: 16, weight: .semibold)

    // MARK: - SectionHeader
    static let sectionHeaderTitle    = Font.custom("Geologica", size: 28).weight(.medium)
    static let sectionHeaderSubtitle = Font.custom("Geologica", size: 14).weight(.light)

    // MARK: - Fallbacks (system)
    /// Section title — 20 bold
    static let title   = Font.system(size: 20, weight: .bold)
    /// Body text — 14 regular
    static let body    = Font.system(size: 14, weight: .regular)
    /// Small caption — 12 regular
    static let caption = Font.system(size: 12, weight: .regular)
}
