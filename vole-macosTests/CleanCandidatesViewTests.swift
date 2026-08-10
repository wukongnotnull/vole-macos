import XCTest
@testable import vole_macos

final class CleanCandidatesViewTests: XCTestCase {
    private func entry(id: String, size: UInt64) -> VolePlanEntry {
        VolePlanEntry(id: id, path: "/p/\(id)", label: id.uppercased(), size: size, ruleID: "r", skipReason: nil, dev: 0, ino: 0, mtime: 0)
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
}
