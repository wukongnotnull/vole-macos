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
        XCTAssertEqual(SoilStrataView(fraction: nil).mode, .idle)
    }

    func test_indeterminateModeDistinctFromIdle() {
        XCTAssertEqual(SoilStrataView(fraction: nil, indeterminate: true).mode, .indeterminate)
        XCTAssertEqual(SoilStrataView(fraction: 0.3, indeterminate: true).mode, .indeterminate)
    }

    func test_indeterminateIsStaticMeasureBand() {
        XCTAssertEqual(
            SoilStrataView(fraction: nil, indeterminate: true).indeterminatePresentation,
            .staticMeasure
        )
        XCTAssertFalse(
            SoilStrataView(fraction: nil, indeterminate: true).indeterminateUsesSweep
        )
    }

    func test_validFractionPassesThrough() {
        XCTAssertEqual(SoilStrataView(fraction: 0.64).clampedFraction ?? -1, 0.64, accuracy: 0.001)
        XCTAssertEqual(SoilStrataView(fraction: 0.64).mode, .determinate(0.64))
    }

    func test_soilPanelCarriesCaptionAndValue() {
        let panel = SoilPanel(fraction: 0.5, valueText: "2.4 GB", caption: "已选 23 · 共 37")
        XCTAssertEqual(panel.caption, "已选 23 · 共 37")
        XCTAssertEqual(panel.valueText, "2.4 GB")
        XCTAssertFalse(panel.indeterminate)
    }

    func test_soilPanelForwardsIndeterminate() {
        let panel = SoilPanel(
            fraction: nil,
            indeterminate: true,
            valueText: "12",
            caption: "已扫条目"
        )
        XCTAssertTrue(panel.indeterminate)
    }
}
