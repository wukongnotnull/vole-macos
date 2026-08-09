import XCTest
@testable import vole_macos

final class StatusSnapshotTests: XCTestCase {
    func test_decodeMinimalStatusJSON() throws {
        let json = """
        {
          "collected_at": "2026-08-09T05:00:00Z",
          "host": "burrow",
          "platform": "macOS 15.0",
          "uptime": "1d 2h",
          "uptime_seconds": 93600,
          "procs": 420,
          "health_score": 88,
          "health_score_msg": "良好",
          "cpu": {
            "usage": 12.5,
            "load1": 1.1,
            "load5": 1.0,
            "load15": 0.9,
            "core_count": 8,
            "logical_cpu": 8
          },
          "memory": {
            "used": 8000000000,
            "total": 16000000000,
            "available": 8000000000,
            "used_percent": 50.0,
            "swap_used": 0,
            "swap_total": 0,
            "pressure": "normal"
          },
          "disks": [
            {
              "mount": "/",
              "device": "disk3s1",
              "used": 100,
              "total": 200,
              "used_percent": 50.0,
              "fstype": "apfs",
              "external": false,
              "smart_status": "verified"
            }
          ],
          "trash_size": 1024,
          "trash_approx": false
        }
        """
        let snap = try StatusSnapshot.decode(fromJSONLine: json)
        XCTAssertEqual(snap.host, "burrow")
        XCTAssertEqual(snap.healthScore, 88)
        XCTAssertEqual(snap.cpu.usage, 12.5, accuracy: 0.001)
        XCTAssertEqual(snap.memory.usedPercent, 50.0, accuracy: 0.001)
        XCTAssertEqual(snap.disks.count, 1)
        XCTAssertEqual(snap.disks[0].mount, "/")
        XCTAssertEqual(snap.trashSize, 1024)
        XCTAssertNil(snap.localSnapshots)
    }

    func test_decodeLocalSnapshotsOptional() throws {
        let json = """
        {
          "collected_at": "t",
          "host": "h",
          "platform": "p",
          "uptime": "u",
          "uptime_seconds": 1,
          "procs": 1,
          "health_score": 1,
          "health_score_msg": "m",
          "cpu": {
            "usage": 0, "load1": 0, "load5": 0, "load15": 0,
            "core_count": 1, "logical_cpu": 1
          },
          "memory": {
            "used": 0, "total": 1, "available": 1, "used_percent": 0,
            "swap_used": 0, "swap_total": 0, "pressure": "normal"
          },
          "disks": [],
          "trash_size": 0,
          "trash_approx": true,
          "local_snapshots": { "count": 2, "message": "2 snapshots" }
        }
        """
        let snap = try StatusSnapshot.decode(fromJSONLine: json)
        XCTAssertEqual(snap.localSnapshots?.count, 2)
        XCTAssertEqual(snap.localSnapshots?.message, "2 snapshots")
    }
}
