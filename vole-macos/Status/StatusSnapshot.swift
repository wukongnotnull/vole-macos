import Foundation

/// Desktop subset of CLI `StatusSnapshot` (`vole status --json`, snake_case).
struct StatusSnapshot: Codable, Equatable {
    var collectedAt: String
    var host: String
    var platform: String
    var uptime: String
    var uptimeSeconds: UInt64
    var procs: UInt64
    var healthScore: Int
    var healthScoreMsg: String
    var cpu: StatusCPU
    var memory: StatusMemory
    var disks: [StatusDisk]
    var trashSize: UInt64
    var trashApprox: Bool
    var localSnapshots: StatusLocalSnapshots?

    static func decode(from data: Data) throws -> StatusSnapshot {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(StatusSnapshot.self, from: data)
    }

    static func decode(fromJSONLine line: String) throws -> StatusSnapshot {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmed.data(using: .utf8) else {
            throw StatusDecodeError.invalidUTF8
        }
        return try decode(from: data)
    }
}

struct StatusCPU: Codable, Equatable {
    var usage: Double
    var load1: Double
    var load5: Double
    var load15: Double
    var coreCount: Int
    var logicalCpu: Int
}

struct StatusMemory: Codable, Equatable {
    var used: UInt64
    var total: UInt64
    var available: UInt64
    var usedPercent: Double
    var swapUsed: UInt64
    var swapTotal: UInt64
    var pressure: String
}

struct StatusDisk: Codable, Equatable, Identifiable {
    var mount: String
    var device: String
    var used: UInt64
    var total: UInt64
    var usedPercent: Double
    var fstype: String
    var external: Bool
    var smartStatus: String

    var id: String { "\(device):\(mount)" }
}

struct StatusLocalSnapshots: Codable, Equatable {
    var count: UInt64?
    var message: String
}

enum StatusDecodeError: Error {
    case invalidUTF8
    case emptyOutput
}
