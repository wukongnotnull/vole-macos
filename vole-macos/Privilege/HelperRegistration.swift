import Foundation
import ServiceManagement

enum HelperRegistrationStatus: Equatable, Sendable {
    case notRegistered
    case enabled
    case requiresApproval
    case notFound
    case unknown(String)

    var isReadyForXPC: Bool { self == .enabled }
}

enum HelperRegistration {
    static var service: SMAppService {
        SMAppService.daemon(plistName: HelperServiceIDs.launchDaemonPlistName)
    }

    static func currentStatus() -> HelperRegistrationStatus {
        map(service.status)
    }

    @discardableResult
    static func register() throws -> HelperRegistrationStatus {
        try service.register()
        return currentStatus()
    }

    static func unregister() throws {
        try service.unregister()
    }

    static func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    static func map(_ status: SMAppService.Status) -> HelperRegistrationStatus {
        switch status {
        case .notRegistered:
            return .notRegistered
        case .enabled:
            return .enabled
        case .requiresApproval:
            return .requiresApproval
        case .notFound:
            return .notFound
        @unknown default:
            return .unknown(String(describing: status))
        }
    }
}
