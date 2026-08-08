import Foundation
import Testing
@testable import vole_macos

struct SidecarRunnerTests {
    /// PRODUCT_NAME must not case-fold-collide with the embedded `vole` sidecar
    /// (APFS default is case-insensitive). Collision turns `vole --version` into
    /// a recursive re-launch of the SwiftUI app.
    @Test func embeddedVoleIsDistinctFromAppExecutable() throws {
        let voleURL = try #require(SidecarRunner.bundledVoleURL())
        let appURL = try #require(Bundle.main.executableURL)

        var voleStat = stat()
        var appStat = stat()
        #expect(stat(voleURL.path, &voleStat) == 0)
        #expect(stat(appURL.path, &appStat) == 0)
        #expect(
            voleStat.st_ino != appStat.st_ino,
            "Contents/MacOS/vole inode matches app executable — PRODUCT_NAME likely collides with sidecar on case-insensitive FS"
        )
    }

    @Test func mapsExitCodes() {
        #expect(SidecarRunner.mapExitCode(0, stderr: "") == .success)
        #expect(SidecarRunner.mapExitCode(130, stderr: "cancelled") == .cancelled)
        let failed = SidecarRunner.mapExitCode(1, stderr: "另一个 vole clean 正在运行")
        guard case let .failed(message) = failed else {
            Issue.record("expected failed")
            return
        }
        #expect(message.contains("正在运行"))
    }

    @Test func mapsSigtermToCancelled() {
        #expect(
            SidecarRunner.mapExitCode(15, stderr: "", terminationReason: .uncaughtSignal)
                == .cancelled
        )
    }

    @Test func mapsSigintToCancelled() {
        #expect(
            SidecarRunner.mapExitCode(2, stderr: "", terminationReason: .uncaughtSignal)
                == .cancelled
        )
    }

    @Test func mapsCancelRequestedToCancelled() {
        #expect(
            SidecarRunner.mapExitCode(1, stderr: "interrupted", cancelRequested: true)
                == .cancelled
        )
    }

    @Test func successWinsOverCancelRequested() {
        #expect(
            SidecarRunner.mapExitCode(0, stderr: "", cancelRequested: true) == .success
        )
    }
}
