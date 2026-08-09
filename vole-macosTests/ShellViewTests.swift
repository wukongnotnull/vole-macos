import XCTest
@testable import vole_macos

final class ShellViewTests: XCTestCase {
    func test_allModulesAvailable() {
        XCTAssertEqual(
            ShellModule.allCases.map(\.isAvailable),
            Array(repeating: true, count: 8)
        )
        XCTAssertEqual(
            ShellModule.allCases.map(\.title),
            ["清理", "卸载", "优化", "净化", "安装包", "分析", "历史", "状态"]
        )
    }

    func test_moduleOrderStable() {
        XCTAssertEqual(
            ShellModule.allCases,
            [.clean, .uninstall, .optimize, .purge, .installer, .analyze, .history, .status]
        )
    }
}
