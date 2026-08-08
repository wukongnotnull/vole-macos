import Foundation
import Testing
@testable import vole_macos

struct PathAuthorizationTests {
    @Test func acceptsWhitelistedPrefixes() throws {
        let samples = [
            "/Library/Caches/com.example.cache",
            "/Library/LaunchDaemons/com.example.plist",
            "/Library/LaunchAgents/com.example.plist",
            "/private/tmp/vole-test-dir",
            "/private/var/tmp/vole-test-dir",
            "/private/var/log/vole-test.log",
            "/private/var/db/diagnostics/vole-test",
            "/private/var/db/DiagnosticPipeline/vole-test",
            "/private/var/db/powerlog/vole-test",
            "/Library/PrivilegedHelperTools/com.example.helper",
        ]
        for path in samples {
            let authorized = try PathAuthorization.authorizePath(path)
            #expect(authorized.hasPrefix(PathAuthorization.allowedPrefixes.first(where: { path.hasPrefix($0) })!))
        }
    }

    @Test func rejectsDeniedAndEscapes() {
        let denied = [
            "/Library/Updates/index.plist",
            "/macOS Install Data/foo",
            "/etc/passwd",
            "/Users/someone/Library/Caches/x",
            "/Library/Caches/../Preferences/com.apple.foo",
            "/tmp/../etc/passwd",
            "",
            "Library/Caches/relative",
        ]
        for path in denied {
            #expect(throws: PathAuthorizationError.self) {
                _ = try PathAuthorization.authorizePath(path)
            }
        }
    }

    @Test func requiresPrivilegeForSystemPrefixesOnly() {
        #expect(PathAuthorization.requiresPrivilegedHelper("/Library/Caches/x"))
        #expect(PathAuthorization.requiresPrivilegedHelper("/private/var/log/x"))
        #expect(PathAuthorization.requiresPrivilegedHelper("/tmp/x"))
        #expect(!PathAuthorization.requiresPrivilegedHelper("/Users/me/Library/Caches/x"))
        #expect(!PathAuthorization.requiresPrivilegedHelper("/Applications/Foo.app"))
    }

    @Test func bootoutLabelValidation() throws {
        #expect(try PathAuthorization.authorizeLaunchdLabel("com.example.agent") == "com.example.agent")
        #expect(throws: PathAuthorizationError.self) {
            _ = try PathAuthorization.authorizeLaunchdLabel("com.apple.WindowServer")
        }
        #expect(throws: PathAuthorizationError.self) {
            _ = try PathAuthorization.authorizeLaunchdLabel("../evil")
        }
        #expect(throws: PathAuthorizationError.self) {
            _ = try PathAuthorization.authorizeLaunchdLabel("com.example;rm -rf /")
        }
    }

    @Test func partitionRoutesSystemPathsToHelper() {
        let user = VolePlanEntry(
            id: "u", path: "/Users/me/Library/Caches/x", label: "u", size: 1,
            ruleID: "r", skipReason: nil, dev: 0, ino: 0, mtime: 0
        )
        let system = VolePlanEntry(
            id: "s", path: "/Library/Caches/x", label: "s", size: 1,
            ruleID: "r", skipReason: nil, dev: 0, ino: 0, mtime: 0
        )
        let parts = PrivilegedApply.partition([user, system])
        #expect(parts.userEntries.map(\.id) == ["u"])
        #expect(parts.privilegedEntries.map(\.id) == ["s"])
        #expect(PrivilegedApply.launchdLabel(fromPath: "/Library/LaunchDaemons/com.example.plist") == "com.example")
        #expect(PrivilegedApply.launchdLabel(fromPath: "/Library/LaunchDaemons/com.apple.foo.plist") == nil)
    }
}
