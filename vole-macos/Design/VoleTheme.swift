import SwiftUI
import AppKit

/// Vole design-system single source: color / type / spacing / radius / shadow / motion.
/// Views must reference these tokens instead of hardcoding constants.
enum VoleTheme {

    // MARK: Color

    enum Colors {
        /// Sidebar base (constant across appearances).
        static let ink = Color(hex: 0x3E322A)
        /// Window / shell canvas.
        static let canvas = Color(hex: 0xEFE6DB)
        /// Content card surface.
        static let card = Color(hex: 0xFFFFFF)
        /// Brand accent: selection, strata mid, emphasis.
        static let fur = Color(hex: 0xC99971)
        /// Primary actions (scan / clean / confirm).
        static let soil = Color(hex: 0x8A6A52)
        /// App icon ground; strata terminal stop, badges/empty states. Not a text color.
        static let sage = Color(hex: 0xC9D8B6)
        /// Layering / skip-zone background.
        static let molehill = Color(hex: 0xE0D0BE)
        /// Micro-accent: success hint / mascot blush. Never a primary CTA.
        static let blush = Color(hex: 0xF4A6A1)
        /// Primary text (light content).
        static let text = Color(hex: 0x3E322A)

        /// Content background that flips with appearance.
        static let contentBackground = Color(light: 0xFFFFFF, dark: 0x1C1613)
        /// Primary text on ink sidebar.
        static let onInk = Color(hex: 0xFAF6F0)
        /// Selected sidebar label.
        static let onFur = Color(hex: 0x2E2721)
        /// Strata gradient mid stop between soil and fur.
        static let strataMid = Color(hex: 0xB3895F)
    }

    // MARK: Type

    enum TypeScale {
        /// Module title (e.g. "翻土找缓存").
        static func title() -> Font { .system(size: 22, weight: .bold, design: .rounded) }
        /// Eyebrow / overline (e.g. "CLEAN · 清理").
        static func eyebrow() -> Font { .system(size: 11, weight: .bold, design: .rounded) }
        /// Section heading.
        static func headline() -> Font { .system(size: 14, weight: .semibold, design: .rounded) }
        /// Body copy.
        static func body() -> Font { .system(size: 13, weight: .regular, design: .default) }
        /// Captions / meta.
        static func caption() -> Font { .system(size: 11, weight: .regular, design: .default) }
        /// Bytes / counts / paths — tabular monospace.
        static func metric() -> Font { .system(size: 13, weight: .semibold, design: .monospaced) }
        static func metricLarge() -> Font { .system(size: 22, weight: .bold, design: .monospaced) }
    }

    // MARK: Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: Radius

    enum Radius {
        static let card: CGFloat = 12
        static let control: CGFloat = 9
        static let strata: CGFloat = 6
    }

    // MARK: Shadow

    enum Shadow {
        static let card = Color(hex: 0x2C211C, alpha: 0.12)
    }

    // MARK: Motion

    enum Motion {
        static let quick: Double = 0.15
        static let standard: Double = 0.25
        static let slow: Double = 0.35
        static var easing: Animation { .timingCurve(0.32, 0.72, 0, 1, duration: standard) }
    }
}

// MARK: - Color helpers

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    init(light: UInt32, dark: UInt32) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return NSColor(hex: isDark ? dark : light)
        })
    }
}

extension NSColor {
    convenience init(hex: UInt32) {
        self.init(
            calibratedRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
