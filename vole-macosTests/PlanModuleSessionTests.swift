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

    func test_worktreeAgentKindFlags() {
        XCTAssertEqual(PlanModuleKind.worktree.command, "worktree")
        XCTAssertEqual(PlanModuleKind.agent.command, "agent")
        XCTAssertEqual(PlanModuleKind.worktree.planFilePrefix, "worktree-full")
        XCTAssertEqual(PlanModuleKind.agent.applyFilePrefix, "agent-apply")
        XCTAssertTrue(PlanModuleKind.worktree.supportsPermanentDelete)
        XCTAssertTrue(PlanModuleKind.agent.supportsPermanentDelete)
        XCTAssertTrue(PlanModuleKind.purge.selectsAllCandidatesByDefault)
        XCTAssertTrue(PlanModuleKind.installer.selectsAllCandidatesByDefault)
        XCTAssertTrue(PlanModuleKind.uninstall.selectsAllCandidatesByDefault)
        XCTAssertTrue(PlanModuleKind.optimize.selectsAllCandidatesByDefault)
        XCTAssertFalse(PlanModuleKind.worktree.selectsAllCandidatesByDefault)
        XCTAssertFalse(PlanModuleKind.agent.selectsAllCandidatesByDefault)
    }

    func test_worktreeAgentCopyRiskPhrases() {
        XCTAssertEqual(PlanModuleKind.worktree.title, "Worktree")
        XCTAssertEqual(PlanModuleKind.agent.title, "Agent")
        XCTAssertEqual(PlanModuleKind.worktree.idleEyebrow, "Worktree · 工作树")
        XCTAssertEqual(PlanModuleKind.agent.idleEyebrow, "Agent · 代理残留")
        XCTAssertEqual(PlanModuleKind.worktree.idleHeadline, "翻出被遗忘的 checkout")
        XCTAssertEqual(PlanModuleKind.agent.idleHeadline, "翻出 Agent 留下的容器")
        XCTAssertTrue(PlanModuleKind.worktree.idleCaption.contains("不宣称可安全删除"))
        XCTAssertTrue(PlanModuleKind.agent.idleCaption.contains("不宣称可安全删除"))
        XCTAssertFalse(PlanModuleKind.agent.idleCaption.contains("放心删"))
        XCTAssertEqual(PlanModuleKind.worktree.candidatesTitle, "挑要移走的 checkout")
        XCTAssertEqual(PlanModuleKind.agent.candidatesTitle, "挑要移走的残留")
        XCTAssertEqual(PlanModuleKind.worktree.primaryActionTitle, "清理所选")
        XCTAssertEqual(PlanModuleKind.agent.primaryActionTitle, "清理所选")
        XCTAssertEqual(PlanModuleKind.worktree.confirmButton, "确认清理")
        XCTAssertEqual(PlanModuleKind.agent.confirmButton, "确认清理")
        XCTAssertEqual(PlanModuleKind.worktree.resultTitle, "Worktree 清理完成")
        XCTAssertEqual(PlanModuleKind.agent.resultTitle, "Agent 清理完成")

        let wt = PlanModuleKind.worktree.confirmTitle(permanentDelete: false)
        let ag = PlanModuleKind.agent.confirmTitle(permanentDelete: false)
        XCTAssertTrue(wt.contains("不宣称可安全删除"))
        XCTAssertTrue(ag.contains("不宣称可安全删除"))
        XCTAssertTrue(wt.contains("废纸篓"))
        XCTAssertTrue(ag.contains("废纸篓"))
        XCTAssertTrue(wt.contains("整棵 Git checkout"))
        XCTAssertTrue(ag.contains("容器"))
        XCTAssertFalse(ag.contains("Git checkout") && ag.contains("将删除已选的整棵"))

        let wtPerm = PlanModuleKind.worktree.confirmTitle(permanentDelete: true)
        let agPerm = PlanModuleKind.agent.confirmTitle(permanentDelete: true)
        XCTAssertTrue(wtPerm.contains("将永久删除，不可从废纸篓恢复"))
        XCTAssertTrue(agPerm.contains("将永久删除，不可从废纸篓恢复"))
    }
}
