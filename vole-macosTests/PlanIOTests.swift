import Foundation
import Testing
@testable import vole_macos

struct PlanIOTests {
    private func samplePlan() -> VolePlan {
        VolePlan(
            schemaVersion: 1,
            createdAt: 1_700_000_000,
            ttlSecs: 900,
            entries: [
                VolePlanEntry(
                    id: "a", path: "/tmp/a", label: "A", size: 1,
                    ruleID: "r", skipReason: nil, dev: 1, ino: 2, mtime: 3
                ),
                VolePlanEntry(
                    id: "b", path: "/tmp/b", label: "B", size: 2,
                    ruleID: "r", skipReason: "whitelisted", dev: 1, ino: 3, mtime: 3
                ),
            ],
            coverageNote: "n"
        )
    }

    @Test func filterKeepsSelectedEntriesAndMetadata() {
        let filtered = PlanIO.filter(plan: samplePlan(), selectedIDs: Set(["a"]))
        #expect(filtered.entries.map(\.id) == ["a"])
        #expect(filtered.createdAt == 1_700_000_000)
        #expect(filtered.ttlSecs == 900)
        #expect(filtered.entries[0].dev == 1)
        #expect(filtered.entries[0].ino == 2)
    }

    @Test func expiredWhenPastTTL() {
        let plan = samplePlan()
        let now = Date(timeIntervalSince1970: TimeInterval(plan.createdAt + plan.ttlSecs + 1))
        #expect(PlanIO.isExpired(plan, now: now))
        let fresh = Date(timeIntervalSince1970: TimeInterval(plan.createdAt + 10))
        #expect(!PlanIO.isExpired(plan, now: fresh))
    }

    @Test func writeReadRoundTrip() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("vole-planio-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("plan.json")
        try PlanIO.write(samplePlan(), to: url)
        let loaded = try PlanIO.read(from: url)
        #expect(loaded.entries.count == 2)
        #expect(loaded.entries[0].mtime == 3)
    }
}
