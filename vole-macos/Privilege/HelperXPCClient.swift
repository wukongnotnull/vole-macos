import Foundation

enum HelperXPCClientError: Error, Equatable, LocalizedError {
    case notEnabled(HelperRegistrationStatus)
    case connectionFailed
    case remoteProxyUnavailable

    var errorDescription: String? {
        switch self {
        case .notEnabled(let status):
            return "Privileged helper is not enabled (status: \(status))"
        case .connectionFailed:
            return "Failed to connect to privileged helper"
        case .remoteProxyUnavailable:
            return "Privileged helper proxy unavailable"
        }
    }
}

enum HelperXPCClient {
    static func ping() async throws -> (pid: Int32, uid: Int32) {
        let status = HelperRegistration.currentStatus()
        guard status.isReadyForXPC else {
            throw HelperXPCClientError.notEnabled(status)
        }

        let connection = NSXPCConnection(
            machServiceName: HelperServiceIDs.machServiceName,
            options: .privileged
        )
        connection.remoteObjectInterface = NSXPCInterface(with: VoleHelperProtocol.self)
        connection.resume()
        defer {
            connection.invalidate()
        }

        let proxy = connection.remoteObjectProxyWithErrorHandler { _ in } as? VoleHelperProtocol
        guard let proxy else {
            throw HelperXPCClientError.remoteProxyUnavailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            var settled = false
            let finish: (Result<(pid: Int32, uid: Int32), Error>) -> Void = { result in
                guard !settled else { return }
                settled = true
                continuation.resume(with: result)
            }

            connection.interruptionHandler = {
                finish(.failure(HelperXPCClientError.connectionFailed))
            }
            connection.invalidationHandler = {
                finish(.failure(HelperXPCClientError.connectionFailed))
            }

            proxy.ping { pid, uid in
                finish(.success((pid: pid, uid: uid)))
            }
        }
    }
}
