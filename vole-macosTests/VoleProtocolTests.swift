import Foundation
import Testing
@testable import vole_macos

struct VoleProtocolTests {
    @Test func decodesProgressLine() throws {
        let line = #"{"schema_version":1,"type":"progress","scanned":128,"current":"~/Library/Caches"}"#
        let event = try VoleStreamEvent.decodeNDJSONLine(line)
        guard case let .progress(scanned, current) = event else {
            Issue.record("expected progress")
            return
        }
        #expect(scanned == 128)
        #expect(current == "~/Library/Caches")
    }

    @Test func decodesCandidateLine() throws {
        let line = #"{"schema_version":1,"type":"candidate","id":"c-1","path":"/tmp/a","label":"A","size":1024,"rule_id":"chrome-cache"}"#
        let event = try VoleStreamEvent.decodeNDJSONLine(line)
        guard case let .candidate(id, path, label, size, ruleID) = event else {
            Issue.record("expected candidate")
            return
        }
        #expect(id == "c-1")
        #expect(path == "/tmp/a")
        #expect(label == "A")
        #expect(size == 1024)
        #expect(ruleID == "chrome-cache")
    }

    @Test func planRoundTripPreservesIdentityFields() throws {
        let json = """
        {
          "schema_version": 1,
          "created_at": 1700000000,
          "ttl_secs": 900,
          "coverage_note": "note",
          "entries": [
            {
              "id": "chrome-cache-0",
              "path": "/Users/test/Library/Caches/Google",
              "label": "Chrome cache",
              "size": 1024,
              "rule_id": "chrome-cache",
              "skip_reason": null,
              "dev": 17,
              "ino": 42,
              "mtime": 1700000001
            }
          ]
        }
        """
        let data = Data(json.utf8)
        let plan = try JSONDecoder().decode(VolePlan.self, from: data)
        #expect(plan.schemaVersion == 1)
        #expect(plan.entries.count == 1)
        #expect(plan.entries[0].dev == 17)
        #expect(plan.entries[0].ino == 42)
        let encoded = try JSONEncoder().encode(plan)
        let again = try JSONDecoder().decode(VolePlan.self, from: encoded)
        #expect(again.entries[0].dev == 17)
        #expect(again.entries[0].mtime == 1700000001)
    }
}
