import XCTest
@testable import vole_macos

final class AnalyzeSnapshotTests: XCTestCase {
    func test_decodeAnalyzeOutput() throws {
        let json = """
        {"path":"/tmp","overview":false,"entries":[{"name":"a","path":"/tmp/a","size":10,"is_dir":true}],"large_files":[{"name":"b","path":"/tmp/b","size":99}],"total_size":100,"total_files":2}
        """
        let snap = try AnalyzeSnapshot.decode(fromJSONLine: json)
        XCTAssertEqual(snap.path, "/tmp")
        XCTAssertEqual(snap.entries.count, 1)
        XCTAssertEqual(snap.entries[0].name, "a")
        XCTAssertTrue(snap.entries[0].isDir)
        XCTAssertEqual(snap.largeFiles.first?.size, 99)
        XCTAssertEqual(snap.totalSize, 100)
        XCTAssertEqual(snap.totalFiles, 2)
    }
}
