import XCTest
@testable import vole_macos

final class SettingsToolsModelTests: XCTestCase {
    func test_settingsToolArguments() {
        XCTAssertEqual(
            SettingsToolsModel.touchIdArgs(action: "status"),
            ["touchid", "status", "--json"]
        )
        XCTAssertEqual(
            SettingsToolsModel.updateCheckArgs(),
            ["update", "--check", "--json"]
        )
        XCTAssertEqual(
            SettingsToolsModel.updateApplyArgs(force: false, nightly: false),
            ["update", "--yes", "--json"]
        )
        XCTAssertEqual(
            SettingsToolsModel.removeDryRunArgs(purgeOplog: false),
            ["remove", "--dry-run", "--json"]
        )
        XCTAssertEqual(
            SettingsToolsModel.removeApplyArgs(purgeOplog: true),
            ["remove", "--yes", "--json", "--purge-oplog"]
        )
    }
}
