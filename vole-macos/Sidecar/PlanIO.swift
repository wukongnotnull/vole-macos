import Foundation

enum PlanIO {
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
        return try JSONDecoder().decode(VolePlan.self, from: data)
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
