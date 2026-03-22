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

    // MARK: - SectionHeader
    static let sectionHeaderTitle    = Color.black
    static let sectionHeaderSubtitle = Color(red: 0.463, green: 0.427, blue: 0.651)

    // MARK: - ProgressBar
    static let progressBarFill        = Color.white
    static let progressBarTrack       = Color.white.opacity(0.3)
    static let progressBarText        = Color.white
    static let progressBarTrackText   = Color.white.opacity(0.3)  // inactive: "/ 58 GB"

    static let surface    = Color(.secondarySystemBackground)

    static var background: LinearGradient {
        let degrees = 176.0
        let radians = (degrees - 90) * Double.pi / 180
        let x = cos(radians)
        let y = sin(radians)
        let start = UnitPoint(x: 0.5 - 0.5 * x, y: 0.5 - 0.5 * y)
        let end = UnitPoint(x: 0.5 + 0.5 * x, y: 0.5 + 0.5 * y)
        return LinearGradient(
            stops: [
                .init(color: Color(red: 195 / 255, green: 194 / 255, blue: 212 / 255), location: 0),
                .init(color: Color(red: 214 / 255, green: 207 / 255, blue: 227 / 255), location: 0.2413),
                .init(color: Color(red: 206 / 255, green: 196 / 255, blue: 226 / 255), location: 0.5691),
                .init(color: Color(red: 189 / 255, green: 197 / 255, blue: 243 / 255), location: 0.947),
                .init(color: Color(red: 189 / 255, green: 197 / 255, blue: 243 / 255), location: 1),
            ],
            startPoint: start,
            endPoint: end
        )
    }
}
