import XCTest
@testable import vole_macos

final class ApplyProgressTests: XCTestCase {
    func test_applyProgressFraction_nilWhenTotalZero() {
        XCTAssertNil(applyProgressFraction(scanned: 3, total: 0))
    }

    func test_applyProgressFraction_scalesAndCapsAtOne() {
        XCTAssertEqual(applyProgressFraction(scanned: 0, total: 10) ?? -1, 0, accuracy: 0.001)
        XCTAssertEqual(applyProgressFraction(scanned: 5, total: 10) ?? -1, 0.5, accuracy: 0.001)
        XCTAssertEqual(applyProgressFraction(scanned: 10, total: 10) ?? -1, 1, accuracy: 0.001)
        XCTAssertEqual(applyProgressFraction(scanned: 12, total: 10) ?? -1, 1, accuracy: 0.001)
    }

    func test_applyUsesIndeterminate_whenNoTotal() {
        XCTAssertTrue(applyUsesIndeterminateProgress(scanned: 0, total: 0, progressCurrent: ""))
    }

    func test_applyUsesIndeterminate_duringHelperPhase() {
        XCTAssertTrue(
            applyUsesIndeterminateProgress(
                scanned: 4,
                total: 10,
                progressCurrent: "root权限助手正在删除需管理员权限的文件…"
            )
        )
    }

    func test_applyUsesDeterminate_duringSidecarApply() {
        XCTAssertFalse(
            applyUsesIndeterminateProgress(scanned: 4, total: 10, progressCurrent: "/tmp/cache")
        )
    }

    func test_applyProgressValueText() {
        XCTAssertEqual(applyProgressValueText(scanned: 4, total: 10), "4 / 10")
    }
}
