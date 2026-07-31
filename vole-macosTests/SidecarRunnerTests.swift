import Foundation
import Testing
@testable import vole_macos

struct SidecarRunnerTests {
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
