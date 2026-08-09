import Foundation

/// Desktop decode of CLI `AnalyzeOutput` (`vole analyze --json`, snake_case).
struct AnalyzeSnapshot: Codable, Equatable {
    var path: String
    var overview: Bool
    var entries: [AnalyzeEntryItem]
    var largeFiles: [AnalyzeFileItem]
    var totalSize: Int64
    var totalFiles: Int64?

    static func decode(from data: Data) throws -> AnalyzeSnapshot {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(AnalyzeSnapshot.self, from: data)
    }

    static func decode(fromJSONLine line: String) throws -> AnalyzeSnapshot {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmed.data(using: .utf8) else {
            throw AnalyzeDecodeError.invalidUTF8
        }
        return try decode(from: data)
    }
}

struct AnalyzeEntryItem: Codable, Equatable, Identifiable {
    var name: String
    var path: String
    var size: Int64
    var isDir: Bool
    var insight: Bool?
    var cleanable: Bool?
    var lastAccess: String?

    var id: String { path }
}

struct AnalyzeFileItem: Codable, Equatable, Identifiable {
    var name: String
    var path: String
    var size: Int64

    var id: String { path }
}

enum AnalyzeDecodeError: Error {
    case invalidUTF8
}
