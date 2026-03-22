import SwiftUI
import UIKit
import CoreText

// MARK: - All text styles in one place.

enum AppFonts {

    private static let geologicaWghtAxis = NSNumber(value: 2003265652) // 'wght'

    private static func geologica(size: CGFloat, wght: CGFloat) -> Font {
        let variation: [NSNumber: NSNumber] = [geologicaWghtAxis: NSNumber(value: Double(wght))]
        let variationKey = UIFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String)
        let base = UIFontDescriptor(name: "Geologica-Thin", size: size)
        let descriptor = base.addingAttributes([variationKey: variation])
        return Font(UIFont(descriptor: descriptor, size: size))
    }

    // MARK: - Button
    static let button = geologica(size: 16, wght: 600)

    // MARK: - SectionHeader
    static let sectionHeaderTitle    = geologica(size: 28, wght: 600)
    static let sectionHeaderSubtitle = geologica(size: 14, wght: 300)

    // MARK: - ProgressBar
    static let progressBarLabel = geologica(size: 20, wght: 500)

    // MARK: - Fallbacks (system)
    /// Section title — 20 bold
    static let title   = Font.system(size: 20, weight: .bold)
    /// Body text — 14 regular
    static let body    = Font.system(size: 14, weight: .regular)
    /// Small caption — 12 regular
    static let caption = Font.system(size: 12, weight: .regular)
}
