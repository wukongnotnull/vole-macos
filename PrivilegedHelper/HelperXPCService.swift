import Foundation
import Security

final class HelperXPCService: NSObject, NSXPCListenerDelegate, VoleHelperProtocol {
    func listener(
        _ listener: NSXPCListener,
        shouldAcceptNewConnection newConnection: NSXPCConnection
    ) -> Bool {
        guard isAuthorizedClient(newConnection) else {
            return false
        }

        newConnection.exportedInterface = NSXPCInterface(with: VoleHelperProtocol.self)
        newConnection.exportedObject = self
        newConnection.invalidationHandler = { [weak newConnection] in
            newConnection?.invalidationHandler = nil
        }
        newConnection.resume()
        return true
    }

    func ping(reply: @escaping (Int32, Int32) -> Void) {
        reply(getpid(), Int32(getuid()))
    }

    func removeAuthorizedPaths(
        _ paths: [String],
        reply: @escaping (Bool, String?) -> Void
    ) {
        guard !paths.isEmpty else {
            reply(false, "No paths provided")
            return
        }

        var authorized: [String] = []
        authorized.reserveCapacity(paths.count)
        for path in paths {
            do {
                authorized.append(try PathAuthorization.authorizePath(path))
            } catch {
                reply(false, error.localizedDescription)
                return
            }
        }

        let fm = FileManager.default
        for path in authorized {
            do {
                if fm.fileExists(atPath: path) {
                    try fm.removeItem(atPath: path)
                }
            } catch {
                reply(false, "Failed to remove \(path): \(error.localizedDescription)")
                return
            }
        }
        reply(true, nil)
    }

    func bootoutLaunchdLabel(
        _ label: String,
        reply: @escaping (Bool, String?) -> Void
    ) {
        let authorized: String
        do {
            authorized = try PathAuthorization.authorizeLaunchdLabel(label)
        } catch {
            reply(false, error.localizedDescription)
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["bootout", "system/\(authorized)"]
        let stderr = Pipe()
        process.standardOutput = Pipe()
        process.standardError = stderr
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            reply(false, "Failed to run launchctl: \(error.localizedDescription)")
            return
        }

        if process.terminationStatus == 0 {
            reply(true, nil)
            return
        }

        let errData = stderr.fileHandleForReading.readDataToEndOfFile()
        let errText = String(data: errData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        reply(false, errText?.isEmpty == false ? errText : "launchctl bootout failed (\(process.terminationStatus))")
    }

    private func isAuthorizedClient(_ connection: NSXPCConnection) -> Bool {
        var guest: SecCode?
        let attrs: [CFString: Any] = [
            kSecGuestAttributePid: connection.processIdentifier,
        ]
        let guestStatus = SecCodeCopyGuestWithAttributes(
            nil,
            attrs as CFDictionary,
            [],
            &guest
        )
        guard guestStatus == errSecSuccess, let guest else {
            return allowDebugFallback(connection)
        }

        var staticCode: SecStaticCode?
        let staticStatus = SecCodeCopyStaticCode(guest, [], &staticCode)
        guard staticStatus == errSecSuccess, let staticCode else {
            return allowDebugFallback(connection)
        }

        let requirementString =
            "anchor apple generic and certificate leaf[subject.OU] = \"\(HelperServiceIDs.teamIdentifier)\" "
            + "and identifier \"\(HelperServiceIDs.appBundleIdentifier)\""
        var requirement: SecRequirement?
        let reqStatus = SecRequirementCreateWithString(
            requirementString as CFString,
            [],
            &requirement
        )
        guard reqStatus == errSecSuccess, let requirement else {
            return false
        }

        let validity = SecStaticCodeCheckValidity(staticCode, [], requirement)
        if validity == errSecSuccess {
            return true
        }

        return allowDebugFallback(connection)
    }

    /// Debug-only: accept same-Team unsigned/ad-hoc clients while local signing settles.
    private func allowDebugFallback(_ connection: NSXPCConnection) -> Bool {
        #if DEBUG
        // When the helper is already root, only accept non-root app clients from the console user.
        if getuid() == 0 {
            return connection.effectiveUserIdentifier != 0
        }
        return connection.effectiveUserIdentifier == getuid()
        #else
        _ = connection
        return false
        #endif
    }
}
