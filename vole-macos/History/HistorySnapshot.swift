import Foundation

/// Desktop decode of CLI `history --json` (snake_case).
struct HistorySnapshot: Codable, Equatable {
    var logs: HistoryLogsInfo
    var limit: UInt
    var sessions: [HistorySessionItem]
    var deletions: [HistoryDeletionItem]

    static func decode(from data: Data) throws -> HistorySnapshot {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(HistorySnapshot.self, from: data)
    }

    static func decode(fromJSONLine line: String) throws -> HistorySnapshot {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmed.data(using: .utf8) else {
            throw HistoryDecodeError.invalidUTF8
        }
        return try decode(from: data)
    }
}

struct HistoryLogsInfo: Codable, Equatable {
    var operations: String
    var deletions: String
}

struct HistoryActionsInfo: Codable, Equatable {
    var removed: UInt64
    var trashed: UInt64
    var skipped: UInt64
    var failed: UInt64
    var rebuilt: UInt64
    var other: UInt64
}

struct HistorySessionItem: Codable, Equatable, Identifiable {
    var command: String
    var startedAt: String
    var endedAt: String
    var items: UInt64
    var size: String
    var operationCount: UInt64
    var actions: HistoryActionsInfo

    var id: String { "\(command)-\(startedAt)-\(operationCount)" }

    var actionsSummary: String {
        "删\(actions.removed) · 篓\(actions.trashed) · 跳\(actions.skipped) · 败\(actions.failed)"
    }
}

struct HistoryDeletionItem: Codable, Equatable, Identifiable {
    var timestamp: String
    var mode: String
    var status: String
    var sizeKb: UInt64?
    var path: String

    var id: String { "\(timestamp)-\(path)" }
}

enum HistoryDecodeError: Error {
    case invalidUTF8
}
