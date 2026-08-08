import Foundation

enum HelperXPCClientError: Error, Equatable, LocalizedError {
    case notEnabled(HelperRegistrationStatus)
    case connectionFailed
    case remoteProxyUnavailable
    case helperRejected(String)

    var errorDescription: String? {
        switch self {
        case .notEnabled(let status):
            return "Privileged helper is not enabled (status: \(status))"
        case .connectionFailed:
            return "Failed to connect to privileged helper"
        case .remoteProxyUnavailable:
            return "Privileged helper proxy unavailable"
        case .helperRejected(let message):
            return message
        }
    }
}

enum HelperXPCClient {
    static func ping() async throws -> (pid: Int32, uid: Int32) {
        try await withProxy { proxy, finish in
            proxy.ping { pid, uid in
                finish(.success((pid: pid, uid: uid)))
            }
        }
    }

    static func removeAuthorizedPaths(_ paths: [String]) async throws {
        try await withProxy { proxy, finish in
            proxy.removeAuthorizedPaths(paths) { ok, error in
                if ok {
                    finish(.success(()))
                } else {
                    finish(.failure(HelperXPCClientError.helperRejected(error ?? "removeAuthorizedPaths failed")))
                }
            }
        }
    }

    static func bootoutLaunchdLabel(_ label: String) async throws {
        try await withProxy { proxy, finish in
            proxy.bootoutLaunchdLabel(label) { ok, error in
                if ok {
                    finish(.success(()))
                } else {
                    finish(.failure(HelperXPCClientError.helperRejected(error ?? "bootoutLaunchdLabel failed")))
                }
            }
        }
    }

    private static func withProxy<T: Sendable>(
        _ body: @escaping (VoleHelperProtocol, @escaping (Result<T, Error>) -> Void) -> Void
    ) async throws -> T {
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
            let finish: (Result<T, Error>) -> Void = { result in
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

            body(proxy, finish)
        }
    }
}
