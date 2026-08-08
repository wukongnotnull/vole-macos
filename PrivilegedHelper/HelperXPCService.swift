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
            "anchor apple generic and certificate leaf[subject.OU] = \"\(HelperServiceIDs.teamIdentifier)\""
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

    /// Debug-only: accept unsigned/ad-hoc same-user clients while skeleton signing is unsettled.
    private func allowDebugFallback(_ connection: NSXPCConnection) -> Bool {
        #if DEBUG
        return connection.effectiveUserIdentifier == getuid()
            || connection.effectiveUserIdentifier == 0
        #else
        _ = connection
        return false
        #endif
    }
}
