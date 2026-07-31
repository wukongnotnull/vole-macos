import Foundation

enum PlanIOError: LocalizedError {
    case unsupportedSchema(UInt32)

    var errorDescription: String? {
        switch self {
        case let .unsupportedSchema(version):
            return "不支持的 plan schema_version=\(version)，请重新扫描"
        }
    }
}

enum PlanIO {
    static let expectedSchemaVersion: UInt32 = 1

    static func filter(plan: VolePlan, selectedIDs: Set<String>) -> VolePlan {
        var copy = plan
        copy.entries = plan.entries.filter { selectedIDs.contains($0.id) }
        return copy
    }

    static func isExpired(_ plan: VolePlan, now: Date = Date()) -> Bool {
        let expiry = Date(timeIntervalSince1970: TimeInterval(plan.createdAt + plan.ttlSecs))
        return now >= expiry
    }

    static func write(_ plan: VolePlan, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(plan)
        try data.write(to: url, options: .atomic)
    }

    static func read(from url: URL) throws -> VolePlan {
        let data = try Data(contentsOf: url)
        let plan = try JSONDecoder().decode(VolePlan.self, from: data)
        guard plan.schemaVersion == expectedSchemaVersion else {
            throw PlanIOError.unsupportedSchema(plan.schemaVersion)
        }
        return plan
    }

    static func cachesDirectory() throws -> URL {
        let base = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = base.appendingPathComponent("cn.waytoai.vole-macos", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
