import AppKit
import SwiftUI

/// Resolves a macOS app icon from bundle id / path, falling back to a system symbol.
struct CandidateAppLogoView: View {
    let lookup: CandidateAppIconLookup
    var size: CGFloat = 22

    var body: some View {
        Group {
            if let image = resolvedImage {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: fallbackSymbol)
                    .font(.system(size: size * 0.72, weight: .semibold))
                    .foregroundStyle(VoleTheme.Colors.soil)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .accessibilityHidden(true)
    }

    private var fallbackSymbol: String {
        if case let .systemSymbol(name) = lookup {
            return name
        }
        return "app"
    }

    private var resolvedImage: NSImage? {
        switch lookup {
        case let .bundleIdentifier(bundleID):
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                return NSWorkspace.shared.icon(forFile: url.path)
            }
            return nil
        case let .applicationPath(path):
            guard FileManager.default.fileExists(atPath: path) else { return nil }
            return NSWorkspace.shared.icon(forFile: path)
        case .systemSymbol:
            return nil
        }
    }
}
