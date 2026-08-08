import XCTest
import SwiftUI
@testable import vole_macos

final class SoilStrataViewTests: XCTestCase {
    func test_fractionClampedToZeroOne() {
        XCTAssertEqual(SoilStrataView(fraction: 1.4).clampedFraction ?? -1, 1.0, accuracy: 0.001)
        XCTAssertEqual(SoilStrataView(fraction: -0.2).clampedFraction ?? -1, 0.0, accuracy: 0.001)
    }

    func test_nilFractionIsIdle() {
        XCTAssertNil(SoilStrataView(fraction: nil).clampedFraction)
    }

    func test_validFractionPassesThrough() {
        XCTAssertEqual(SoilStrataView(fraction: 0.64).clampedFraction ?? -1, 0.64, accuracy: 0.001)
    }

    func test_soilPanelCarriesCaptionAndValue() {
        let panel = SoilPanel(fraction: 0.5, valueText: "2.4 GB", caption: "已选 23 · 共 37")
        XCTAssertEqual(panel.caption, "已选 23 · 共 37")
        XCTAssertEqual(panel.valueText, "2.4 GB")
    }
}
