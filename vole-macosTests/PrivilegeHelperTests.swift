import Foundation
import ServiceManagement
import Testing
@testable import vole_macos

struct PrivilegeHelperTests {
    @Test func serviceIdentifiersMatchDesign() {
        #expect(HelperServiceIDs.machServiceName == "cn.waytoai.vole-macos.helper")
        #expect(HelperServiceIDs.launchDaemonPlistName == "cn.waytoai.vole-macos.helper.plist")
        #expect(HelperServiceIDs.helperExecutableName == "VolePrivilegedHelper")
        #expect(HelperServiceIDs.appBundleIdentifier == "cn.waytoai.vole-macos")
        #expect(HelperServiceIDs.teamIdentifier == "WCYC8XY4V2")
    }

    @Test func statusMappingCoversKnownCases() {
        #expect(HelperRegistration.map(.notRegistered) == .notRegistered)
        #expect(HelperRegistration.map(.enabled) == .enabled)
        #expect(HelperRegistration.map(.requiresApproval) == .requiresApproval)
        #expect(HelperRegistration.map(.notFound) == .notFound)
        #expect(HelperRegistrationStatus.enabled.isReadyForXPC)
        #expect(!HelperRegistrationStatus.requiresApproval.isReadyForXPC)
        #expect(!HelperRegistrationStatus.notRegistered.isReadyForXPC)
    }

    @Test func xpcClientRefusesWhenNotEnabled() async {
        let status = HelperRegistration.currentStatus()
        guard status != .enabled else {
            // Helper already approved on this machine; skip negative-path assertion.
            return
        }
        do {
            _ = try await HelperXPCClient.ping()
            Issue.record("ping should fail when helper is not enabled")
        } catch let error as HelperXPCClientError {
            #expect(error == .notEnabled(status))
        } catch {
            Issue.record("unexpected error: \(error)")
        }
    }
}
