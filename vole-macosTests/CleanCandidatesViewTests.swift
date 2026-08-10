import XCTest
import SwiftUI
import AppKit
@testable import vole_macos

final class CleanCandidatesViewTests: XCTestCase {
    private func components(_ color: Color) -> (CGFloat, CGFloat, CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        NSColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (round(r * 255), round(g * 255), round(b * 255))
    }

    private func entry(id: String, size: UInt64) -> VolePlanEntry {
        VolePlanEntry(id: id, path: "/p/\(id)", label: id.uppercased(), size: size, ruleID: "r", skipReason: nil, dev: 0, ino: 0, mtime: 0)
    }

    func test_listStyle_denseRowChrome() {
        XCTAssertEqual(CleanCandidatesListStyle.rowVerticalPadding, 3)
        XCTAssertEqual(CleanCandidatesListStyle.checkboxSize, 14)
        XCTAssertEqual(CleanCandidatesListStyle.chromeControlSpacing, VoleTheme.Spacing.xs)
        XCTAssertEqual(CleanCandidatesListStyle.chipVerticalPadding, 4)
    }

    func test_listStyle_selectionAndFilterUseFurBrandAccent() {
        let selection = components(CleanCandidatesListStyle.selectionFill)
        let filterSelected = components(CleanCandidatesListStyle.filterChipSelectedFill)
        let fur = components(VoleTheme.Colors.fur)
        XCTAssertEqual(selection.0, fur.0, accuracy: 1)
        XCTAssertEqual(selection.1, fur.1, accuracy: 1)
        XCTAssertEqual(selection.2, fur.2, accuracy: 1)
        XCTAssertEqual(filterSelected.0, fur.0, accuracy: 1)
        XCTAssertEqual(filterSelected.1, fur.1, accuracy: 1)
        XCTAssertEqual(filterSelected.2, fur.2, accuracy: 1)

        // Guard against accidental system-blue chrome.
        XCTAssertFalse(selection.0 == 0 && selection.1 == 122 && selection.2 == 255)
    }

    func test_selectedTotalBytesSumsSelectedOnly() {
        let a = entry(id: "a", size: 100)
        let b = entry(id: "b", size: 50)
        XCTAssertEqual(selectedTotalBytes(entries: [a, b], selectedIDs: ["a"]), 100)
        XCTAssertEqual(selectedTotalBytes(entries: [a, b], selectedIDs: ["a", "b"]), 150)
        XCTAssertEqual(selectedTotalBytes(entries: [a, b], selectedIDs: []), 0)
    }

    func test_strataFraction() {
        let a = entry(id: "a", size: 100)
        let b = entry(id: "b", size: 100)
        XCTAssertEqual(strataFraction(entries: [a, b], selectedIDs: ["a"]), 0.5, accuracy: 0.001)
        XCTAssertEqual(strataFraction(entries: [a, b], selectedIDs: []), 0.0, accuracy: 0.001)
        XCTAssertEqual(strataFraction(entries: [], selectedIDs: []), 0.0, accuracy: 0.001)
    }

    func test_layoutMetrics_resolveBreakpoints() {
        let wideTall = CleanCandidatesLayoutMetrics.resolve(width: 800, height: 700)
        XCTAssertTrue(wideTall.isWide)
        XCTAssertTrue(wideTall.isTall)
        XCTAssertEqual(wideTall.contentPadding, VoleTheme.Spacing.xl)

        let narrowShort = CleanCandidatesLayoutMetrics.resolve(width: 500, height: 400)
        XCTAssertFalse(narrowShort.isWide)
        XCTAssertFalse(narrowShort.isTall)
        XCTAssertEqual(narrowShort.contentPadding, VoleTheme.Spacing.md)
        XCTAssertEqual(narrowShort.sectionSpacing, VoleTheme.Spacing.sm)
    }

    func test_layoutMetrics_alwaysShowsEyebrow() {
        let tall = CleanCandidatesLayoutMetrics.resolve(width: 800, height: 700)
        let short = CleanCandidatesLayoutMetrics.resolve(width: 500, height: 400)
        XCTAssertTrue(tall.showsEyebrow)
        XCTAssertTrue(short.showsEyebrow)
    }
}
