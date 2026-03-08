import SwiftUI

// MARK: - App Color Tokens
// Single source of truth for all colors used across the app.
// Organized by component. Add new colors here as you discover them in Figma.

enum AppColors {

    // MARK: - Button
    static let buttonPrimaryBackground   = Color(red: 0.269, green: 0.141, blue: 1)
    static let buttonSecondaryBackground = Color(red: 0.485, green: 0.492, blue: 0.922)
    static let buttonPrimaryText         = Color.white
    static let buttonSecondaryText       = Color.white

    // MARK: - Toggle
    static let toggleActiveBackground    = Color(red: 0.269, green: 0.141, blue: 1)
    static let toggleInactiveBackground  = Color(red: 0.796, green: 0.777, blue: 0.903)
    static let toggleThumb               = Color.white

    // MARK: - General / Background
    static let background = Color(.systemBackground)
    static let surface    = Color(.secondarySystemBackground)
}
