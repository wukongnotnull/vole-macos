import XCTest
@testable import vole_macos

final class ShellViewTests: XCTestCase {
    func test_allModulesAvailable() {
        XCTAssertEqual(ShellModule.allCases.map(\.isAvailable), [true, true, true, true])
        XCTAssertEqual(ShellModule.allCases.map(\.title), ["清理", "卸载", "优化", "状态"])
    }

    func test_moduleOrderStable() {
        XCTAssertEqual(ShellModule.allCases, [.clean, .uninstall, .optimize, .status])
    }
}
