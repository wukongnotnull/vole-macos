import Foundation
import Testing
@testable import vole_macos

struct SidecarVersionTests {
    @Test func parsesVolePrefix() {
        let v = SidecarVersion.parse("vole 2.20.0")
        #expect(v?.major == 2)
        #expect(v?.minor == 20)
        #expect(v?.patch == 0)
    }

    @Test func parsesVoleCliPrefix() {
        let v = SidecarVersion.parse("vole-cli 2.20.0")
        #expect(v?.major == 2)
        #expect(v?.minor == 20)
        #expect(v?.patch == 0)
    }

    @Test func usesFirstSemVerOnFirstLine() {
        let raw = "vole 2.20.1 (rev abc)\nextra 9.9.9"
        let v = SidecarVersion.parse(raw)
        #expect(v?.major == 2)
        #expect(v?.minor == 20)
        #expect(v?.patch == 1)
    }

    @Test func prereleaseStillUsesMajorMinor() {
        #expect(SidecarVersion.supportsWorktreeAgent("vole 2.20.0-beta.1"))
        #expect(SidecarVersion.supportsWorktreeAgent("vole 2.20.3"))
    }

    @Test func rejectsNon220AndGarbage() {
        #expect(!SidecarVersion.supportsWorktreeAgent("vole 2.19.9"))
        #expect(!SidecarVersion.supportsWorktreeAgent("vole 2.21.0"))
        #expect(!SidecarVersion.supportsWorktreeAgent("vole"))
        #expect(!SidecarVersion.supportsWorktreeAgent(""))
        #expect(SidecarVersion.parse("no version here") == nil)
    }
}
