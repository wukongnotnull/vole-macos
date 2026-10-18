import XCTest

/// Shared queries for Vole UI tests. Labels are the app's Chinese UI strings.
extension XCTestCase {
    func staticText(_ app: XCUIApplication, _ s: String) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", s, s)).firstMatch
    }

    /// Window-scoped so Touch Bar mirrors of dialog buttons are never matched.
    func windowButton(_ app: XCUIApplication, _ s: String) -> XCUIElement {
        app.windows.buttons.matching(NSPredicate(format: "label == %@ OR title == %@", s, s)).firstMatch
    }

    func openModule(_ app: XCUIApplication, _ title: String, file: StaticString = #filePath, line: UInt = #line) {
        let b = app.buttons.matching(NSPredicate(format: "label == %@ OR label ENDSWITH %@", title, ", " + title)).firstMatch
        XCTAssertTrue(b.waitForExistence(timeout: 10), "sidebar \(title) missing\n\(app.debugDescription)", file: file, line: line)
        b.click()
    }

    /// Attaches one screenshot per display. `XCUIScreen.main` alone misses a window on
    /// an external display, and `XCUIElement.screenshot()` hard-fails there.
    func snap(_ app: XCUIApplication, _ label: String) {
        for (i, screen) in XCUIScreen.screens.enumerated() {
            let a = XCTAttachment(screenshot: screen.screenshot())
            a.name = XCUIScreen.screens.count > 1 ? "\(label) (display \(i + 1))" : label
            a.lifetime = .keepAlways
            add(a)
        }
    }

    /// Dismisses the Full Disk Access alert if it shows; returns whether it appeared.
    @discardableResult
    func dismissFDAIfShown(_ app: XCUIApplication, timeout: TimeInterval = 3) -> Bool {
        let later = windowButton(app, "稍后")
        guard later.waitForExistence(timeout: timeout) else { return false }
        snap(app, "FDA alert")
        if later.isHittable { later.click() }
        return true
    }
}
