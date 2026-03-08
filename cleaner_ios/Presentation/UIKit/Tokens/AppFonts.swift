import SwiftUI

// MARK: - App Typography Tokens
// All text styles in one place. Adjust sizes/weights to match Figma.

enum AppFonts {
    /// Button label — 16 semibold
    static let button = Font.system(size: 16, weight: .semibold)
    /// Section title — 20 bold
    static let title   = Font.system(size: 20, weight: .bold)
    /// Body text — 14 regular
    static let body    = Font.system(size: 14, weight: .regular)
    /// Small caption — 12 regular
    static let caption = Font.system(size: 12, weight: .regular)
}
