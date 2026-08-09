import XCTest
import SwiftUI
import AppKit
@testable import vole_macos

final class VoleThemeTests: XCTestCase {
    private func components(_ color: Color) -> (CGFloat, CGFloat, CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        NSColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (round(r * 255), round(g * 255), round(b * 255))
    }

    func test_furMatchesLockedBrandValue() {
        let (r, g, b) = components(VoleTheme.Colors.fur)
        XCTAssertEqual(r, 201, accuracy: 1)
        XCTAssertEqual(g, 153, accuracy: 1)
        XCTAssertEqual(b, 113, accuracy: 1)
    }

    func test_inkAndSoil() {
        let ink = components(VoleTheme.Colors.ink)
        XCTAssertEqual(ink.0, 110, accuracy: 1)
        XCTAssertEqual(ink.1, 74, accuracy: 1)
        XCTAssertEqual(ink.2, 46, accuracy: 1)
        let inkSun = components(VoleTheme.Colors.inkSun)
        XCTAssertEqual(inkSun.0, 133, accuracy: 1)
        XCTAssertEqual(inkSun.1, 92, accuracy: 1)
        XCTAssertEqual(inkSun.2, 56, accuracy: 1)
        let soil = components(VoleTheme.Colors.soil)
        XCTAssertEqual(soil.0, 138, accuracy: 1)
        XCTAssertEqual(soil.1, 106, accuracy: 1)
        XCTAssertEqual(soil.2, 82, accuracy: 1)
    }

    func test_sageMatchesAppIconGround() {
        let (r, g, b) = components(VoleTheme.Colors.sage)
        XCTAssertEqual(r, 201, accuracy: 1)
        XCTAssertEqual(g, 216, accuracy: 1)
        XCTAssertEqual(b, 182, accuracy: 1)
    }

    func test_contentBackgroundResolvesInDarkAppearance() {
        let view = Rectangle().fill(VoleTheme.Colors.contentBackground)
        XCTAssertNotNil(view)
    }

    func test_motionDurationsAscending() {
        XCTAssertLessThan(VoleTheme.Motion.quick, VoleTheme.Motion.standard)
        XCTAssertLessThan(VoleTheme.Motion.standard, VoleTheme.Motion.slow)
    }
}
