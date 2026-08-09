import XCTest
@testable import vole_macos

final class MascotActivityTests: XCTestCase {
    func test_mapsSessionPhases() {
        XCTAssertEqual(MascotActivity.from(sessionPhase: .idle), .idle)
        XCTAssertEqual(MascotActivity.from(sessionPhase: .candidates), .idle)
        XCTAssertEqual(MascotActivity.from(sessionPhase: .scanning), .scanning)
        XCTAssertEqual(MascotActivity.from(sessionPhase: .applying), .applying)
        XCTAssertEqual(MascotActivity.from(sessionPhase: .result), .success)
    }

    func test_aggregatePrefersApplyingOverScanning() {
        XCTAssertEqual(
            MascotActivity.aggregate([.scanning, .applying, .idle]),
            .applying
        )
    }

    func test_aggregatePrefersScanningOverSuccess() {
        XCTAssertEqual(
            MascotActivity.aggregate([.success, .scanning, .idle]),
            .scanning
        )
    }

    func test_aggregateIdleWhenOnlyIdleOrEmpty() {
        XCTAssertEqual(MascotActivity.aggregate([]), .idle)
        XCTAssertEqual(MascotActivity.aggregate([.idle, .idle]), .idle)
    }

    func test_aggregateSuccessWhenOnlyResultPhases() {
        XCTAssertEqual(MascotActivity.aggregate([.idle, .success]), .success)
    }

    func test_shellBusyFromCleanAndPlanPhases() {
        XCTAssertEqual(
            MascotActivity.resolve(
                clean: .scanning,
                plans: [.idle, .idle, .idle, .idle]
            ),
            .scanning
        )
        XCTAssertEqual(
            MascotActivity.resolve(
                clean: .candidates,
                plans: [.idle, .applying, .idle, .idle]
            ),
            .applying
        )
        XCTAssertEqual(
            MascotActivity.resolve(
                clean: .idle,
                plans: [.candidates, .idle, .result, .idle]
            ),
            .success
        )
        XCTAssertEqual(
            MascotActivity.resolve(
                clean: .idle,
                plans: [.idle, .idle, .idle, .idle]
            ),
            .idle
        )
    }

    func test_reduceMotionDisablesLoopingMotion() {
        XCTAssertEqual(
            MascotMotion.profile(for: .scanning, reduceMotion: true),
            .stillBusy
        )
        XCTAssertEqual(
            MascotMotion.profile(for: .applying, reduceMotion: true),
            .stillBusy
        )
        XCTAssertEqual(
            MascotMotion.profile(for: .idle, reduceMotion: true),
            .still
        )
    }

    func test_motionProfilesDistinguishBusyStates() {
        XCTAssertEqual(
            MascotMotion.profile(for: .scanning, reduceMotion: false),
            .scanningLoop
        )
        XCTAssertEqual(
            MascotMotion.profile(for: .applying, reduceMotion: false),
            .applyingLoop
        )
        XCTAssertNotEqual(
            MascotMotion.profile(for: .scanning, reduceMotion: false),
            MascotMotion.profile(for: .applying, reduceMotion: false)
        )
        XCTAssertEqual(
            MascotMotion.profile(for: .success, reduceMotion: false),
            .successSettle
        )
        XCTAssertEqual(
            MascotMotion.profile(for: .idle, reduceMotion: false),
            .still
        )
    }

    func test_accessibilityMarksBusyWithoutMotion() {
        XCTAssertTrue(MascotMotion.isBusyAnnounced(for: .scanningLoop))
        XCTAssertTrue(MascotMotion.isBusyAnnounced(for: .applyingLoop))
        XCTAssertTrue(MascotMotion.isBusyAnnounced(for: .stillBusy))
        XCTAssertFalse(MascotMotion.isBusyAnnounced(for: .still))
        XCTAssertFalse(MascotMotion.isBusyAnnounced(for: .successSettle))
    }
}
