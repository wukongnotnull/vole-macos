import XCTest
@testable import vole_macos

final class CleanIdlePresentationTests: XCTestCase {
    func test_soilCaption_isRecoverableLayerPendingScan() {
        XCTAssertEqual(CleanIdlePresentation.soilCaption, "可回收层 · 待扫描")
    }

    func test_helperTitle_isSystemLevelClean() {
        XCTAssertEqual(CleanIdlePresentation.helperTitle, "系统级清理")
    }

    func test_helperDetail_reflectsRegistrationStatus() {
        XCTAssertEqual(
            CleanIdlePresentation.helperDetail(status: .notRegistered),
            "特权助手 · 未启用"
        )
        XCTAssertEqual(
            CleanIdlePresentation.helperDetail(status: .enabled),
            "特权助手 · 已启用"
        )
        XCTAssertEqual(
            CleanIdlePresentation.helperDetail(status: .requiresApproval),
            "特权助手 · 待系统设置批准"
        )
        XCTAssertEqual(
            CleanIdlePresentation.helperDetail(status: .notFound),
            "特权助手 · 构建缺 Helper"
        )
        XCTAssertEqual(
            CleanIdlePresentation.helperDetail(status: .unknown("x")),
            "特权助手 · 未知"
        )
    }

    func test_fdaCaption_reflectsAuthorization() {
        XCTAssertEqual(CleanIdlePresentation.fdaCaption(denied: false), "FDA · 已授权")
        XCTAssertEqual(CleanIdlePresentation.fdaCaption(denied: true), "FDA · 未授权")
    }

    func test_supportingCopy_explainsIdlePurpose() {
        XCTAssertEqual(
            CleanIdlePresentation.supportingCopy,
            "先扫描用户缓存与可安全清理的文件；系统路径需开启特权助手。"
        )
    }
}
