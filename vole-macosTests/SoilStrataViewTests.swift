import XCTest
import SwiftUI
@testable import vole_macos

final class SoilStrataViewTests: XCTestCase {
    func test_soilPanelCarriesCaptionAndValue() {
        let panel = SoilPanel(valueText: "2.4 GB", caption: "已选 23 · 共 37")
        XCTAssertEqual(panel.caption, "已选 23 · 共 37")
        XCTAssertEqual(panel.valueText, "2.4 GB")
    }
}
