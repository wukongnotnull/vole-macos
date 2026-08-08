import Foundation

/// Shared apply helper for Clean (and future Uninstall) system-path operations.
enum PrivilegedApply {
    struct Partition {
        var userEntries: [VolePlanEntry]
        var privilegedEntries: [VolePlanEntry]
    }

    static func partition(_ entries: [VolePlanEntry]) -> Partition {
        var user: [VolePlanEntry] = []
        var privileged: [VolePlanEntry] = []
        for entry in entries {
            if PathAuthorization.requiresPrivilegedHelper(entry.path) {
                privileged.append(entry)
            } else {
                user.append(entry)
            }
        }
        return Partition(userEntries: user, privilegedEntries: privileged)
    }

    static func launchdLabel(fromPath path: String) -> String? {
        let name = URL(fileURLWithPath: path).lastPathComponent
        guard name.hasSuffix(".plist") else { return nil }
        let label = String(name.dropLast(".plist".count))
        return try? PathAuthorization.authorizeLaunchdLabel(label)
    }

    /// Permanently removes authorized paths; boots out launchd labels for LaunchDaemon/Agent plists.
    static func applyPrivilegedPaths(_ paths: [String]) async throws {
        guard !paths.isEmpty else { return }
        try await HelperXPCClient.removeAuthorizedPaths(paths)

        for path in paths {
            if path.hasPrefix("/Library/LaunchDaemons/")
                || path.hasPrefix("/Library/LaunchAgents/")
            {
                if let label = launchdLabel(fromPath: path) {
                    // Best-effort: path may already be gone; bootout failures are non-fatal if already unloaded.
                    try? await HelperXPCClient.bootoutLaunchdLabel(label)
                }
            }
        }
    }
}
