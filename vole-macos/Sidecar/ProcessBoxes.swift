import Foundation

/// Thread-safe box for capturing stdout lines from a sync callback.
final class LinesBox: @unchecked Sendable {
    private let lock = NSLock()
    private var lines: [String] = []

    nonisolated func append(_ line: String) {
        lock.lock()
        lines.append(line)
        lock.unlock()
    }

    nonisolated func lastTrimmed() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return lines.last?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated func joinedUTF8() -> String {
        lock.lock()
        defer { lock.unlock() }
        return lines.joined(separator: "\n")
    }
}

/// Thread-safe box for capturing the last `.done` report from a sync stdout callback.
final class ReportBox: @unchecked Sendable {
    private let lock = NSLock()
    private var value: VoleReport?

    func set(_ report: VoleReport) {
        lock.lock()
        value = report
        lock.unlock()
    }

    func get() -> VoleReport? {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}
