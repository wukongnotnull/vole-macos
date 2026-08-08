import Foundation

enum PathAuthorizationError: Error, Equatable, LocalizedError {
    case empty
    case notAbsolute
    case deniedPrefix
    case notWhitelisted
    case invalidLaunchdLabel
    case appleSystemLabel

    var errorDescription: String? {
        switch self {
        case .empty:
            return "Path is empty"
        case .notAbsolute:
            return "Path must be absolute"
        case .deniedPrefix:
            return "Path is on the deny list"
        case .notWhitelisted:
            return "Path is outside the privileged helper whitelist"
        case .invalidLaunchdLabel:
            return "Launchd label is invalid"
        case .appleSystemLabel:
            return "Apple system launchd labels cannot be booted out"
        }
    }
}

/// Fail-closed authorization for privileged helper operations.
/// Keep in sync with `PrivilegedHelper/PathAuthorization.swift`.
enum PathAuthorization {
    static let allowedPrefixes: [String] = [
        "/Library/Caches",
        "/Library/LaunchDaemons",
        "/Library/LaunchAgents",
        "/Library/PrivilegedHelperTools",
        "/private/tmp",
        "/private/var/tmp",
        "/private/var/log",
        "/private/var/db/diagnostics",
        "/private/var/db/DiagnosticPipeline",
        "/private/var/db/powerlog",
    ]

    static let deniedPrefixes: [String] = [
        "/Library/Updates",
        "/macOS Install Data",
    ]

    /// Whether Clean UI should route this path through the helper (vs sidecar trash).
    static func requiresPrivilegedHelper(_ path: String) -> Bool {
        let normalized = path.hasPrefix("/tmp/") || path == "/tmp" ? "/private/tmp" + path.dropFirst(4) : path
        return allowedPrefixes.contains { prefix in
            normalized == prefix || normalized.hasPrefix(prefix + "/")
        }
    }

    /// Returns a realpath-normalized absolute path when authorized.
    static func authorizePath(_ path: String) throws -> String {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw PathAuthorizationError.empty }
        guard trimmed.hasPrefix("/") else { throw PathAuthorizationError.notAbsolute }
        if trimmed.contains("\0") { throw PathAuthorizationError.notWhitelisted }

        let candidates = expansionCandidates(for: trimmed)
        for candidate in candidates {
            if let authorized = try? authorizeResolvedCandidate(candidate) {
                return authorized
            }
        }
        // Last attempt: authorize lexical form when the path does not exist yet.
        return try authorizeLexical(trimmed)
    }

    static func authorizeLaunchdLabel(_ label: String) throws -> String {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw PathAuthorizationError.invalidLaunchdLabel }
        let pattern = #"^[A-Za-z0-9][A-Za-z0-9._-]*$"#
        guard trimmed.range(of: pattern, options: .regularExpression) != nil else {
            throw PathAuthorizationError.invalidLaunchdLabel
        }
        if trimmed.hasPrefix("com.apple.") {
            throw PathAuthorizationError.appleSystemLabel
        }
        return trimmed
    }

    private static func expansionCandidates(for path: String) -> [String] {
        var out = [path]
        if path.hasPrefix("/tmp/") || path == "/tmp" {
            out.append("/private/tmp" + path.dropFirst(4))
        }
        if path.hasPrefix("/var/") {
            out.append("/private/var" + path.dropFirst(4))
        }
        return out
    }

    private static func authorizeResolvedCandidate(_ path: String) throws -> String {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        let exists = fm.fileExists(atPath: path, isDirectory: &isDir)
        if exists {
            let url = URL(fileURLWithPath: path).resolvingSymlinksInPath().standardizedFileURL
            return try authorizeLexical(url.path)
        }
        return try authorizeLexical(path)
    }

    private static func authorizeLexical(_ path: String) throws -> String {
        let standardized = (path as NSString).standardizingPath
        guard standardized.hasPrefix("/") else { throw PathAuthorizationError.notAbsolute }
        if standardized.contains("..") { throw PathAuthorizationError.notWhitelisted }

        for denied in deniedPrefixes {
            if standardized == denied || standardized.hasPrefix(denied + "/") {
                throw PathAuthorizationError.deniedPrefix
            }
        }

        for prefix in allowedPrefixes {
            if standardized == prefix || standardized.hasPrefix(prefix + "/") {
                // Reject symlink escape: resolved path must still stay in whitelist.
                let resolved = URL(fileURLWithPath: standardized).resolvingSymlinksInPath().path
                let finalPath = (resolved as NSString).standardizingPath
                for denied in deniedPrefixes {
                    if finalPath == denied || finalPath.hasPrefix(denied + "/") {
                        throw PathAuthorizationError.deniedPrefix
                    }
                }
                let stillAllowed = allowedPrefixes.contains {
                    finalPath == $0 || finalPath.hasPrefix($0 + "/")
                }
                guard stillAllowed else { throw PathAuthorizationError.notWhitelisted }
                return finalPath
            }
        }
        throw PathAuthorizationError.notWhitelisted
    }
}
