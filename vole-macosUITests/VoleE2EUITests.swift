import XCTest

/// Opt-in end-to-end click-through that really applies plans, but only against a
/// throwaway HOME built by `scripts/make-ui-fixtures.sh`.
///
/// Skipped unless `VOLE_UI_HOME` is set (pass `TEST_RUNNER_VOLE_UI_HOME=...` to
/// xcodebuild). Refuses to run unless that folder carries the fixture marker and is
/// not the real home folder. Destructive steps only ever tick rows whose label
/// contains the fixture HOME path and a fixture name. Tests are numbered because
/// test12 checks the history written by the earlier applies.
final class VoleE2EUITests: XCTestCase {
    static let markerName = ".vole-ui-fixture"

    private var app: XCUIApplication!
    private var home: String!

    override func setUpWithError() throws {
        continueAfterFailure = false
        guard let fixtureHome = ProcessInfo.processInfo.environment["VOLE_UI_HOME"], !fixtureHome.isEmpty else {
            throw XCTSkip("set TEST_RUNNER_VOLE_UI_HOME to a folder made by scripts/make-ui-fixtures.sh")
        }
        let resolved = URL(fileURLWithPath: fixtureHome).standardizedFileURL.resolvingSymlinksInPath().path
        let realHome = URL(fileURLWithPath: NSHomeDirectory()).standardizedFileURL.resolvingSymlinksInPath().path
        guard resolved != realHome, resolved != "/" else {
            throw XCTSkip("VOLE_UI_HOME must not be the real home folder")
        }
        guard FileManager.default.fileExists(atPath: resolved + "/" + Self.markerName) else {
            throw XCTSkip("VOLE_UI_HOME has no \(Self.markerName); build it with scripts/make-ui-fixtures.sh")
        }
        home = fixtureHome
        app = XCUIApplication()
        app.launchEnvironment["HOME"] = home
        app.launchEnvironment["VOLE_OPERATIONS_LOG"] = home + "/oplog.log"
        app.launchEnvironment["VOLE_DELETE_LOG"] = home + "/deletelog.log"
        app.launch()
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 15))
    }

    override func tearDownWithError() throws {
        guard let app else { return }
        snap(app, "\(name) end")
        app.terminate()
    }

    // MARK: helpers

    private func scanPlanModule(_ title: String, candidatesTitle: String, timeout: TimeInterval = 120) {
        openModule(app, title)
        let scan = windowButton(app, "开始扫描")
        XCTAssertTrue(scan.waitForExistence(timeout: 10))
        scan.click()
        dismissFDAIfShown(app)
        let header = staticText(app, candidatesTitle)
        let empty = staticText(app, "当前无候选")
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline, !header.exists, !empty.exists {
            _ = header.waitForExistence(timeout: 2)
            dismissFDAIfShown(app, timeout: 0.5)
        }
        snap(app, "\(title) candidates")
        XCTAssertTrue(header.exists, "\(title): candidates view not reached\n\(app.debugDescription)")
    }

    /// Clears the selection, then ticks only rows whose label contains the fixture HOME path
    /// and one of the needles, scrolling each into view first.
    private func selectOnly(_ needles: [String]) -> Int {
        windowButton(app, "全不选").click()
        let pred = NSPredicate(format: "label CONTAINS %@", home)
        let labels = app.windows.checkBoxes.matching(pred).allElementsBoundByIndex
            .map(\.label)
            .filter { label in needles.contains(where: { label.contains($0) }) }
        let listPoint = app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.55))
        var picked = 0
        for label in labels {
            let box = app.windows.checkBoxes.matching(NSPredicate(format: "label == %@", label)).firstMatch
            var tries = 0
            while !box.isHittable && tries < 120 {
                listPoint.scroll(byDeltaX: 0, deltaY: tries < 60 ? -200 : 200)
                tries += 1
            }
            guard box.isHittable else { continue }
            if (box.value as? Int) != 1 { box.click() }
            picked += 1
        }
        return picked
    }

    private func selectedRowCount() -> Int {
        app.windows.checkBoxes.matching(NSPredicate(format: "label CONTAINS %@ AND value == 1", ", /")).count
    }

    private func applyAndWait(primary: String, confirm: String, title: String) {
        let go = windowButton(app, primary)
        XCTAssertTrue(go.isEnabled, "\(primary) disabled")
        go.click()
        let ok = windowButton(app, confirm)
        XCTAssertTrue(ok.waitForExistence(timeout: 5), "confirm dialog missing\n\(app.debugDescription)")
        ok.click()
        let done = staticText(app, "Result · 完成")
        XCTAssertTrue(done.waitForExistence(timeout: 120), "\(title): result not reached\n\(app.debugDescription)")
        snap(app, "\(title) result")
    }

    private func gone(_ rel: String) -> Bool {
        !FileManager.default.fileExists(atPath: home + "/" + rel)
    }

    // MARK: tests

    func test03_CleanScanReachesCandidates() {
        openModule(app, "清理")
        windowButton(app, "开始扫描").click()
        dismissFDAIfShown(app)
        let header = staticText(app, "挑要清掉的")
        XCTAssertTrue(header.waitForExistence(timeout: 180), "clean candidates not reached\n\(app.debugDescription)")
        snap(app, "clean candidates")
        XCTAssertTrue(windowButton(app, "清理到废纸篓").exists)
        windowButton(app, "全不选").click()
        // No apply: clean plans include system-wide paths outside the fixture HOME.
    }

    func test04_PurgeFixture() {
        scanPlanModule("净化", candidatesTitle: "挑要净化的")
        XCTAssertGreaterThan(selectOnly(["uijs", "uirs"]), 0, "fixture rows not found\n\(app.debugDescription)")
        applyAndWait(primary: "净化所选", confirm: "确认净化", title: "purge")
        XCTAssertTrue(gone("Projects/uijs/node_modules"))
        XCTAssertTrue(gone("Projects/uirs/target"))
    }

    func test05_InstallerFixture() {
        scanPlanModule("安装包", candidatesTitle: "挑要清理的")
        XCTAssertGreaterThan(selectOnly(["VoleUITestApp"]), 0, "fixture rows not found\n\(app.debugDescription)")
        applyAndWait(primary: "清理所选", confirm: "确认清理", title: "installer")
        XCTAssertTrue(gone("Downloads/VoleUITestApp.dmg"))
    }

    func test06_WorktreeFixture() {
        scanPlanModule("Worktree", candidatesTitle: "挑要移走的 checkout")
        XCTAssertGreaterThan(selectOnly(["uirepo-wt"]), 0, "fixture rows not found\n\(app.debugDescription)")
        applyAndWait(primary: "清理所选", confirm: "确认清理", title: "worktree")
        XCTAssertTrue(gone("Projects/uirepo-wt"), "worktree not trashed")
    }

    func test07_AgentFixture() {
        scanPlanModule("Agent", candidatesTitle: "挑要移走的残留")
        XCTAssertGreaterThan(selectOnly([".cursor"]), 0, "fixture rows not found\n\(app.debugDescription)")
        applyAndWait(primary: "清理所选", confirm: "确认清理", title: "agent")
        XCTAssertTrue(gone(".cursor/Cache"))
    }

    func test08_UninstallFixture() {
        scanPlanModule("卸载", candidatesTitle: "挑要卸载的", timeout: 180)
        let preselected = selectedRowCount()
        let caption = app.windows.staticTexts.matching(NSPredicate(format: "value CONTAINS %@", " 项")).firstMatch
        add(XCTAttachment(string: "uninstall preselected visible rows: \(preselected); caption: \(caption.value ?? "")"))
        XCTAssertGreaterThan(selectOnly(["VoleUIFixture", "voleuifixture"]), 0, "fixture rows not found\n\(app.debugDescription)")
        applyAndWait(primary: "卸载所选", confirm: "确认卸载", title: "uninstall")
        XCTAssertTrue(gone("Applications/VoleUIFixture.app"))
        XCTAssertTrue(gone("Library/Preferences/com.example.voleuifixture.plist"))
    }

    func test09_OptimizeListsTasksWithoutRunning() {
        scanPlanModule("优化", candidatesTitle: "挑要执行的")
        let tasks = app.windows.checkBoxes.matching(NSPredicate(format: "label CONTAINS %@", "optimize:action:"))
        XCTAssertGreaterThan(tasks.count, 0, "optimize tasks not listed")
        XCTAssertEqual(selectedRowCount(), tasks.count, "optimize: expected every task preselected (current design)")
        windowButton(app, "全不选").click()
        XCTAssertFalse(windowButton(app, "执行所选").isEnabled, "execute enabled with nothing selected")
    }

    func test11_AnalyzeChosenFolder() {
        openModule(app, "分析")
        let cancel = windowButton(app, "取消")
        if cancel.waitForExistence(timeout: 3) { cancel.click() }
        let choose = windowButton(app, "选择文件夹")
        XCTAssertTrue(choose.waitForExistence(timeout: 10))
        let enabled = NSPredicate(format: "isEnabled == true")
        expectation(for: enabled, evaluatedWith: choose)
        waitForExpectations(timeout: 10)
        choose.click()
        let panel = app.descendants(matching: .any).matching(identifier: "open-panel").firstMatch
        XCTAssertTrue(panel.waitForExistence(timeout: 10), "open panel missing\n\(app.debugDescription)")
        app.typeKey("g", modifierFlags: [.command, .shift])
        let goTo = app.sheets.matching(identifier: "GoToWindow").firstMatch
        XCTAssertTrue(goTo.waitForExistence(timeout: 5), "go-to sheet missing\n\(app.debugDescription)")
        let field = goTo.textFields.firstMatch.exists ? goTo.textFields.firstMatch : goTo.comboBoxes.firstMatch
        field.click()
        field.typeText(home + "\r")
        let row = panel.textFields.matching(NSPredicate(format: "value == %@", "AnalyzeMe")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10), "AnalyzeMe row missing in panel\n\(app.debugDescription)")
        row.click()
        let ok = panel.buttons.matching(identifier: "OKButton").firstMatch
        expectation(for: NSPredicate(format: "isEnabled == true"), evaluatedWith: ok)
        waitForExpectations(timeout: 10)
        ok.click()
        XCTAssertTrue(staticText(app, "AnalyzeMe").waitForExistence(timeout: 20), "chosen path not shown")
        XCTAssertTrue(staticText(app, "大文件").waitForExistence(timeout: 60), "analyze did not finish\n\(app.debugDescription)")
        XCTAssertTrue(staticText(app, "huge.bin").exists || staticText(app, "big").exists, "fixture not in ranking\n\(app.debugDescription)")
        snap(app, "analyze")
    }

    func test12_HistoryShowsRuns() {
        openModule(app, "历史")
        XCTAssertTrue(staticText(app, "History · 历史").waitForExistence(timeout: 10))
        XCTAssertFalse(staticText(app, "暂无操作记录").waitForExistence(timeout: 5), "history empty after applies")
        for cmd in ["purge", "installer", "worktree", "agent", "uninstall"] {
            XCTAssertTrue(staticText(app, cmd).exists, "history missing \(cmd)")
        }
        snap(app, "history")
    }
}
