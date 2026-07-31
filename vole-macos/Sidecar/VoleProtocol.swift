import Foundation

struct VolePlan: Codable, Equatable {
    var schemaVersion: UInt32
    var createdAt: UInt64
    var ttlSecs: UInt64
    var entries: [VolePlanEntry]
    var coverageNote: String?

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case createdAt = "created_at"
        case ttlSecs = "ttl_secs"
        case entries
        case coverageNote = "coverage_note"
    }
}

struct VolePlanEntry: Codable, Equatable, Identifiable {
    var id: String
    var path: String
    var label: String
    var size: UInt64
    var ruleID: String
    var skipReason: String?
    var dev: UInt64
    var ino: UInt64
    var mtime: UInt64

    enum CodingKeys: String, CodingKey {
        case id, path, label, size
        case ruleID = "rule_id"
        case skipReason = "skip_reason"
        case dev, ino, mtime
    }
}

struct VoleReport: Codable, Equatable {
    var succeeded: UInt64
    var skipped: UInt64
    var failed: UInt64
    var skippedByReason: [VoleSkipSummary]
    var trashedBytes: UInt64
    var deletedBytes: UInt64
    var coverageNote: String?

    enum CodingKeys: String, CodingKey {
        case succeeded, skipped, failed
        case skippedByReason = "skipped_by_reason"
        case trashedBytes = "trashed_bytes"
        case deletedBytes = "deleted_bytes"
        case coverageNote = "coverage_note"
    }
}

struct VoleSkipSummary: Codable, Equatable {
    var reason: String
    var count: UInt64
    var ruleIDs: [String]

    enum CodingKeys: String, CodingKey {
        case reason, count
        case ruleIDs = "rule_ids"
    }
}

enum VoleStreamEvent: Equatable {
    case progress(scanned: UInt64, current: String)
    case candidate(id: String, path: String, label: String, size: UInt64, ruleID: String)
    case skipped(ruleID: String, reason: String)
    case done(report: VoleReport)
    case aborted(reason: String)

    static func decodeNDJSONLine(_ line: String) throws -> VoleStreamEvent {
        let data = Data(line.utf8)
        let raw = try JSONDecoder().decode(RawStreamEvent.self, from: data)
        switch raw.type {
        case "progress":
            return .progress(scanned: raw.scanned ?? 0, current: raw.current ?? "")
        case "candidate":
            return .candidate(
                id: raw.id ?? "",
                path: raw.path ?? "",
                label: raw.label ?? "",
                size: raw.size ?? 0,
                ruleID: raw.ruleID ?? ""
            )
        case "skipped":
            return .skipped(ruleID: raw.ruleID ?? "", reason: raw.reason ?? "")
        case "done":
            guard let report = raw.report else {
                throw VoleProtocolError.missingReport
            }
            return .done(report: report)
        case "aborted":
            return .aborted(reason: raw.reason ?? "")
        default:
            throw VoleProtocolError.unknownType(raw.type)
        }
    }
}

enum VoleProtocolError: Error {
    case missingReport
    case unknownType(String)
}

private struct RawStreamEvent: Decodable {
    var type: String
    var scanned: UInt64?
    var current: String?
    var id: String?
    var path: String?
    var label: String?
    var size: UInt64?
    var ruleID: String?
    var reason: String?
    var report: VoleReport?

    enum CodingKeys: String, CodingKey {
        case type, scanned, current, id, path, label, size, reason, report
        case ruleID = "rule_id"
    }
}
