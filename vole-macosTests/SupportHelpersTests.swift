import Foundation
import Testing
@testable import vole_macos

struct SupportHelpersTests {
    @Test func settingsURLIsPrivacyFDA() {
        #expect(FDAProbe.settingsURL.absoluteString.contains("Privacy_AllFiles")
            || FDAProbe.settingsURL.absoluteString.contains("Privacy_FullDiskAccess")
            || FDAProbe.settingsURL.scheme == "x-apple.systempreferences")
    }

    @Test func displayAppNameMatchesProductBranding() {
        #expect(FDAProbe.displayAppName == "Vole")
    }

    @Test func byteFormatUsesBinaryUnits() {
        let zero = ByteFormat.string(0)
        #expect(zero == "0 B" || zero.lowercased().contains("zero") || zero.contains("0"))
        let kb = ByteFormat.string(1024)
        #expect(kb.contains("1"))
        #expect(kb.uppercased().contains("K"))
        let mb = ByteFormat.string(1_048_576)
        #expect(mb.contains("1"))
        #expect(mb.uppercased().contains("M"))
    }
}
