import SwiftUI

// MARK: - App Color Tokens
// Single source of truth for all colors used across the app.
// Add new colors here as you discover them in Figma.

enum AppColors {

    // MARK: - Brand
    static let primary = Color(red: 0.269, green: 0.141, blue: 1)
    static let secondary = Color(red: 0.485, green: 0.492, blue: 0.922)

    // MARK: - Neutral
    static let background = Color(.systemBackground)
    static let surface     = Color(.secondarySystemBackground)
    static let onPrimary   = Color.white
    static let onSecondary = Color.white
}
