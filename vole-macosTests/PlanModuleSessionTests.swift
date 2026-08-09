import XCTest
@testable import vole_macos

final class PlanModuleSessionTests: XCTestCase {
    func test_kindCommandsMatchCLI() {
        XCTAssertEqual(PlanModuleKind.uninstall.command, "uninstall")
        XCTAssertEqual(PlanModuleKind.optimize.command, "optimize")
        XCTAssertEqual(PlanModuleKind.uninstall.planFilePrefix, "uninstall-full")
        XCTAssertEqual(PlanModuleKind.optimize.applyFilePrefix, "optimize-apply")
    }

    @MainActor
    func test_sessionStartsIdleWithKind() {
        let uninstall = PlanModuleSession(kind: .uninstall)
        XCTAssertEqual(uninstall.kind, .uninstall)
        XCTAssertEqual(uninstall.phase, .idle)
        XCTAssertTrue(uninstall.entries.isEmpty)

        let optimize = PlanModuleSession(kind: .optimize)
        XCTAssertEqual(optimize.kind, .optimize)
        XCTAssertEqual(optimize.phase, .idle)
    }

    func test_copyLocalized() {
        XCTAssertEqual(PlanModuleKind.uninstall.title, "卸载")
        XCTAssertEqual(PlanModuleKind.optimize.primaryActionTitle, "执行所选")
    }
}
