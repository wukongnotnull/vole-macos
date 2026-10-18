import XCTest

/// Smoke tests run by `xcodebuild -scheme vole-macos test`.
///
/// Safety: these tests never click an apply / confirm button, so nothing is moved
/// or deleted. The app is launched with HOME pointing at an empty throwaway folder
/// so the sidecar's user-domain scans see no real files either.
final class VoleSmokeUITests: XCTestCase {
    private var app: XCUIApplication!
    private var home: URL!

    override func setUpWithError() throws {
        continueAfterFailure = false
        home = FileManager.default.temporaryDirectory
            .appendingPathComponent("vole-ui-smoke-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
        app = XCUIApplication()
        app.launchEnvironment["HOME"] = home.path
        app.launchEnvironment["VOLE_OPERATIONS_LOG"] = home.appendingPathComponent("oplog.log").path
        app.launchEnvironment["VOLE_DELETE_LOG"] = home.appendingPathComponent("deletelog.log").path
        app.launch()
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 15), "main window did not appear")
    }

    override func tearDownWithError() throws {
        if let app {
            snap(app, "\(name) end")
            app.terminate()
        }
        if let home { try? FileManager.default.removeItem(at: home) }
    }

    func testLaunchShowsCleanIdle() {
        XCTAssertTrue(staticText(app, "Clean · 清理").waitForExistence(timeout: 10), "clean idle not shown on launch")
        XCTAssertTrue(windowButton(app, "开始扫描").exists, "scan button missing on launch")
    }

    func testSidebarOpensEveryModule() {
        let expect: [(String, String)] = [
            ("清理", "Clean · 清理"), ("卸载", "Uninstall · 卸载"), ("优化", "Optimize · 优化"),
            ("净化", "Purge · 净化"), ("安装包", "Installer · 安装包"), ("Worktree", "Worktree · 工作树"),
            ("Agent", "Agent · 代理残留"), ("分析", "Analyze · 分析"), ("历史", "History · 历史"),
            ("状态", "Status · 状态"),
        ]
        for (title, header) in expect {
            openModule(app, title)
            XCTAssertTrue(staticText(app, header).waitForExistence(timeout: 10), "\(title): header \(header) missing")
            if title == "分析" {
                // Analyze starts sizing HOME on open; stop it before moving on.
                let cancel = windowButton(app, "取消")
                if cancel.waitForExistence(timeout: 2) { cancel.click() }
            }
        }
    }

    func testSettingsSheetOpensAndCloses() {
        openModule(app, "设置")
        XCTAssertTrue(staticText(app, "Settings · 设置").waitForExistence(timeout: 10), "settings sheet missing")
        snap(app, "settings")
        windowButton(app, "完成").click()
        XCTAssertTrue(staticText(app, "Clean · 清理").waitForExistence(timeout: 5), "settings sheet did not close")
    }

    func testCleanScanCancelReturnsToIdle() {
        openModule(app, "清理")
        windowButton(app, "开始扫描").click()
        dismissFDAIfShown(app, timeout: 1)
        let cancel = windowButton(app, "取消")
        XCTAssertTrue(cancel.waitForExistence(timeout: 10), "no cancel while scanning")
        cancel.click()
        XCTAssertTrue(windowButton(app, "开始扫描").waitForExistence(timeout: 5), "did not return to idle after cancel")
        XCTAssertFalse(staticText(app, "另一个").exists, "lock error right after cancel")
        // Rescan right away: the cancelled sidecar must have released the clean lock.
        windowButton(app, "开始扫描").click()
        dismissFDAIfShown(app, timeout: 1)
        XCTAssertTrue(windowButton(app, "取消").waitForExistence(timeout: 10), "rescan did not start")
        XCTAssertFalse(staticText(app, "另一个").waitForExistence(timeout: 3), "rescan hit lock error")
        windowButton(app, "取消").click()
        XCTAssertTrue(windowButton(app, "开始扫描").waitForExistence(timeout: 5), "did not return to idle after second cancel")
    }

    func testPurgeScanOfEmptyHomeFinishesWithoutApplying() {
        openModule(app, "净化")
        let scan = windowButton(app, "开始扫描")
        XCTAssertTrue(scan.waitForExistence(timeout: 10))
        scan.click()
        dismissFDAIfShown(app, timeout: 1)
        let empty = staticText(app, "当前无候选")
        let candidates = staticText(app, "Candidates · 候选")
        let deadline = Date().addingTimeInterval(120)
        while Date() < deadline, !empty.exists, !candidates.exists {
            _ = empty.waitForExistence(timeout: 2)
            dismissFDAIfShown(app, timeout: 0.5)
        }
        snap(app, "purge scanned")
        XCTAssertTrue(empty.exists || candidates.exists, "purge scan did not finish\n\(app.debugDescription)")
        // Deliberately stop here: smoke runs never apply.
    }

    func testStatusShowsLiveMetrics() {
        openModule(app, "状态")
        XCTAssertTrue(staticText(app, "CPU").waitForExistence(timeout: 20), "CPU card missing")
        XCTAssertTrue(staticText(app, "内存").exists, "memory card missing")
        XCTAssertTrue(staticText(app, "磁盘").exists, "disk card missing")
    }

    func testAnalyzeCanBeCancelled() {
        openModule(app, "分析")
        let cancel = windowButton(app, "取消")
        if cancel.waitForExistence(timeout: 3) { cancel.click() }
        let choose = windowButton(app, "选择文件夹")
        XCTAssertTrue(choose.waitForExistence(timeout: 10), "choose-folder button missing")
        expectation(for: NSPredicate(format: "isEnabled == true"), evaluatedWith: choose)
        waitForExpectations(timeout: 10)
    }
}
