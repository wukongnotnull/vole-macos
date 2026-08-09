import XCTest
@testable import vole_macos

final class PlanModuleSessionTests: XCTestCase {
    func test_kindCommandsMatchCLI() {
        XCTAssertEqual(PlanModuleKind.uninstall.command, "uninstall")
        XCTAssertEqual(PlanModuleKind.optimize.command, "optimize")
        XCTAssertEqual(PlanModuleKind.purge.command, "purge")
        XCTAssertEqual(PlanModuleKind.installer.command, "installer")
        XCTAssertEqual(PlanModuleKind.uninstall.planFilePrefix, "uninstall-full")
        XCTAssertEqual(PlanModuleKind.optimize.applyFilePrefix, "optimize-apply")
        XCTAssertTrue(PlanModuleKind.purge.supportsPermanentDelete)
        XCTAssertTrue(PlanModuleKind.installer.supportsPermanentDelete)
        XCTAssertFalse(PlanModuleKind.uninstall.supportsPermanentDelete)
    }

    @MainActor
    func test_applyArgumentsIncludePermanentWhenRequested() {
        let base = PlanModuleSession.applyArguments(
            command: "purge",
            planPath: "/tmp/p.json",
            permanent: true
        )
        XCTAssertEqual(base, ["purge", "--apply", "/tmp/p.json", "--json-stream", "--permanent"])
        let off = PlanModuleSession.applyArguments(
            command: "installer",
            planPath: "/tmp/i.json",
            permanent: false
        )
        XCTAssertEqual(off, ["installer", "--apply", "/tmp/i.json", "--json-stream"])
    }

    @MainActor
    func test_sessionStartsIdleWithKind() {
        let uninstall = PlanModuleSession(kind: .uninstall)
        XCTAssertEqual(uninstall.kind, .uninstall)
        XCTAssertEqual(uninstall.phase, .idle)
        XCTAssertTrue(uninstall.entries.isEmpty)
        XCTAssertFalse(uninstall.permanentDelete)

        let optimize = PlanModuleSession(kind: .optimize)
        XCTAssertEqual(optimize.kind, .optimize)
        XCTAssertEqual(optimize.phase, .idle)

        let purge = PlanModuleSession(kind: .purge)
        XCTAssertEqual(purge.kind, .purge)
        XCTAssertEqual(purge.phase, .idle)
    }

    func test_copyLocalized() {
        XCTAssertEqual(PlanModuleKind.uninstall.title, "卸载")
        XCTAssertEqual(PlanModuleKind.optimize.primaryActionTitle, "执行所选")
        XCTAssertEqual(PlanModuleKind.purge.title, "净化")
        XCTAssertEqual(PlanModuleKind.installer.title, "安装包")
        XCTAssertEqual(PlanModuleKind.purge.primaryActionTitle, "净化所选")
        XCTAssertEqual(PlanModuleKind.installer.primaryActionTitle, "清理所选")
    }
}
