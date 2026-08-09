import XCTest
@testable import vole_macos

final class HistorySnapshotTests: XCTestCase {
    func test_decodeHistoryJSON() throws {
        let json = """
        {"logs":{"operations":"/tmp/ops.log","deletions":"/tmp/del.log"},"limit":2,"sessions":[{"command":"optimize","started_at":"2026-08-09 06:32:24","ended_at":"2026-08-09 06:32:46","items":10,"size":"0B","operation_count":0,"actions":{"removed":0,"trashed":0,"skipped":0,"failed":0,"rebuilt":0,"other":0}}],"deletions":[{"timestamp":"2026-08-08T14:31:31+0000","mode":"trash","status":"ok","size_kb":4,"path":"/tmp/x"}]}
        """
        let snap = try HistorySnapshot.decode(fromJSONLine: json)
        XCTAssertEqual(snap.limit, 2)
        XCTAssertEqual(snap.sessions.first?.command, "optimize")
        XCTAssertEqual(snap.deletions.first?.path, "/tmp/x")
        XCTAssertEqual(snap.deletions.first?.sizeKb, 4)
    }
}
