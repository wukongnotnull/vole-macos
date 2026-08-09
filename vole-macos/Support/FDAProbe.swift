import Foundation
import AppKit

enum FDAProbe {
    /// Known TCC-protected path; listing often fails without Full Disk Access.
    static let probePath = NSHomeDirectory() + "/Library/Mail"

    static var settingsURL: URL {
        // macOS Ventura+ style deep link; falls back still opens System Settings.
        URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
    }

    static func looksDenied() -> Bool {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: probePath, isDirectory: &isDir) else {
            // Path missing on some machines — do not false-alarm.
            return false
        }
        do {
            _ = try fm.contentsOfDirectory(atPath: probePath)
            return false
        } catch {
            return true
        }
    }

    static func openSettings() {
        // Reveal the running bundle so Privacy UI can resolve name/icon (Vole.app),
        // instead of a stale DerivedData `vole-macos.app` TCC entry.
        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
        NSWorkspace.shared.open(settingsURL)
    }

    /// User-facing product name for FDA / privacy prompts (matches CFBundleDisplayName).
    static let displayAppName = "Vole"
}
