import XCTest
@testable import vole_macos

final class CleanResultViewTests: XCTestCase {
    func test_recoveredBytesSumsTrashAndDeleted() {
        let r = VoleReport(succeeded: 1, skipped: 0, failed: 0, skippedByReason: [], trashedBytes: 100, deletedBytes: 50, coverageNote: nil)
        XCTAssertEqual(recoveredBytes(r), 150)
    }

    func test_recoveredBytesZero() {
        let r = VoleReport(succeeded: 0, skipped: 2, failed: 0, skippedByReason: [], trashedBytes: 0, deletedBytes: 0, coverageNote: nil)
        XCTAssertEqual(recoveredBytes(r), 0)
    }
}
