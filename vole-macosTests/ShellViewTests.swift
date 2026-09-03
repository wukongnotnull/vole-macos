import XCTest
@testable import vole_macos

final class ShellViewTests: XCTestCase {
    func test_moduleOrderStable() {
        XCTAssertEqual(
            ShellModule.allCases,
            [
                .clean, .uninstall, .optimize, .purge, .installer,
                .worktree, .agent, .analyze, .history, .status,
            ]
        )
    }

    func test_moduleTitles() {
        XCTAssertEqual(
            ShellModule.allCases.map(\.title),
            ["清理", "卸载", "优化", "净化", "安装包", "Worktree", "Agent", "分析", "历史", "状态"]
        )
    }

    func test_legacyModulesIgnoreSidecarVersion() {
        let old = "vole 2.19.0"
        for module in [ShellModule.clean, .uninstall, .optimize, .purge, .installer, .analyze, .history, .status] {
            XCTAssertTrue(module.isAvailable(sidecarVersion: old), module.rawValue)
            XCTAssertTrue(module.isAvailable(sidecarVersion: ""), module.rawValue)
        }
    }

    func test_worktreeAgentRequire220() {
        XCTAssertTrue(ShellModule.worktree.isAvailable(sidecarVersion: "vole 2.20.0"))
        XCTAssertTrue(ShellModule.agent.isAvailable(sidecarVersion: "vole-cli 2.20.1"))
        XCTAssertTrue(ShellModule.worktree.isAvailable(sidecarVersion: "vole 2.20.0-beta.1"))
        XCTAssertFalse(ShellModule.worktree.isAvailable(sidecarVersion: "vole 2.19.0"))
        XCTAssertFalse(ShellModule.agent.isAvailable(sidecarVersion: "vole 2.21.0"))
        XCTAssertFalse(ShellModule.worktree.isAvailable(sidecarVersion: ""))
        XCTAssertFalse(ShellModule.agent.isAvailable(sidecarVersion: "not-a-version"))
    }

    func test_unavailableHelpIsVersionNotComingSoon() {
        let help = ShellModule.worktree.sidebarHelp(sidecarVersion: "vole 2.19.0")
        XCTAssertEqual(help, "Worktree · 需要内嵌 vole 2.20")
        XCTAssertFalse(help.contains("即将推出"))
        XCTAssertEqual(
            ShellModule.agent.sidebarHelp(sidecarVersion: ""),
            "Agent · 需要内嵌 vole 2.20"
        )
        XCTAssertEqual(ShellModule.worktree.sidebarHelp(sidecarVersion: "vole 2.20.0"), "Worktree")
        XCTAssertEqual(ShellModule.clean.sidebarHelp(sidecarVersion: "vole 2.19.0"), "清理")
    }

    func test_systemImagesDoNotCollide() {
        XCTAssertEqual(ShellModule.worktree.systemImage, "arrow.triangle.branch")
        XCTAssertEqual(ShellModule.agent.systemImage, "cpu")
        XCTAssertEqual(ShellModule.purge.systemImage, "flame")
        XCTAssertEqual(ShellModule.analyze.systemImage, "chart.pie")
        XCTAssertEqual(ShellModule.status.systemImage, "chart.bar")
        let images = ShellModule.allCases.map(\.systemImage)
        XCTAssertEqual(Set(images).count, images.count)
    }
}
