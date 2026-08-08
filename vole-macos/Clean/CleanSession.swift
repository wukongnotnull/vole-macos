import Foundation
import Combine

/// Thread-safe box for capturing stdout lines from a sync callback.
private final class LinesBox: @unchecked Sendable {
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
}

/// Thread-safe box for capturing the last `.done` report from a sync stdout callback.
private final class ReportBox: @unchecked Sendable {
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

@MainActor
final class CleanSession: ObservableObject {
    enum Phase: Equatable {
        case idle
        case scanning
        case candidates
        case applying
        case result
    }

    @Published var phase: Phase = .idle
    @Published var progressScanned: UInt64 = 0
    @Published var progressCurrent: String = ""
    @Published var entries: [VolePlanEntry] = []
    @Published var selectedIDs: Set<String> = []
    @Published var report: VoleReport?
    @Published var errorMessage: String?
    @Published var showFDAAlert: Bool = false
    @Published var voleVersion: String = ""
    @Published var coverageNote: String?
    @Published var helperDegradeNote: String?

    private var process = VoleProcess()
    private var fullPlanURL: URL?
    private var fullPlan: VolePlan?

    func refreshVersion() {
        Task {
            let proc = VoleProcess()
            let linesBox = LinesBox()
            let exit = await proc.run(arguments: ["--version"]) { line in
                linesBox.append(line)
            }
            if case .success = exit {
                voleVersion = linesBox.lastTrimmed() ?? ""
            }
        }
    }

    func startScan() {
        cleanupFullPlan()
        fullPlan = nil
        coverageNote = nil
        errorMessage = nil
        report = nil
        entries = []
        selectedIDs = []
        progressScanned = 0
        progressCurrent = ""
        if FDAProbe.looksDenied() {
            showFDAAlert = true
        }
        phase = .scanning

        Task {
            do {
                let dir = try PlanIO.cachesDirectory()
                let planURL = dir.appendingPathComponent("clean-full-\(UUID().uuidString).json")
                fullPlanURL = planURL
                let exit = await process.run(arguments: [
                    "clean", "--plan", "--json-stream", "--plan-out", planURL.path,
                ]) { [weak self] line in
                    Task { @MainActor in
                        self?.handleStreamLine(line)
                    }
                }
                await handlePlanExit(exit, planURL: planURL)
            } catch {
                phase = .idle
                errorMessage = error.localizedDescription
            }
        }
    }

    func cancel() {
        Task { await process.cancel() }
    }

    func applySelected() {
        guard let plan = fullPlan else {
            errorMessage = "缺少 plan，请重新扫描"
            return
        }
        if PlanIO.isExpired(plan) {
            cleanupFullPlan()
            fullPlan = nil
            entries = []
            selectedIDs = []
            coverageNote = nil
            helperDegradeNote = nil
            errorMessage = "计划已过期，请重新扫描"
            phase = .idle
            return
        }
        let filtered = PlanIO.filter(plan: plan, selectedIDs: selectedIDs)
        guard !filtered.entries.isEmpty else {
            errorMessage = "请至少选择一项"
            return
        }
        let parts = PrivilegedApply.partition(filtered.entries)
        let helperReady = HelperRegistration.currentStatus().isReadyForXPC
        phase = .applying
        errorMessage = nil
        helperDegradeNote = nil

        Task {
            do {
                var sidecarReport: VoleReport?
                if !parts.userEntries.isEmpty {
                    let userPlan = VolePlan(
                        schemaVersion: filtered.schemaVersion,
                        createdAt: filtered.createdAt,
                        ttlSecs: filtered.ttlSecs,
                        entries: parts.userEntries,
                        coverageNote: filtered.coverageNote
                    )
                    let dir = try PlanIO.cachesDirectory()
                    let applyURL = dir.appendingPathComponent("clean-apply-\(UUID().uuidString).json")
                    try PlanIO.write(userPlan, to: applyURL)
                    defer { try? FileManager.default.removeItem(at: applyURL) }

                    let reportBox = ReportBox()
                    let exit = await process.run(arguments: [
                        "clean", "--apply", applyURL.path, "--json-stream",
                    ]) { [weak self] line in
                        guard let event = try? VoleStreamEvent.decodeNDJSONLine(line) else { return }
                        if case let .done(report) = event {
                            reportBox.set(report)
                        }
                        if case let .progress(scanned, current) = event {
                            Task { @MainActor in
                                self?.progressScanned = scanned
                                self?.progressCurrent = current
                            }
                        }
                    }
                    sidecarReport = reportBox.get()
                    switch exit {
                    case .success, .cancelled:
                        break
                    case .failed(let message):
                        cleanupFullPlan()
                        errorMessage = message
                        phase = .candidates
                        return
                    }
                    if case .cancelled = exit {
                        errorMessage = "已取消（可能已部分清理）"
                        report = sidecarReport
                        cleanupFullPlan()
                        phase = .result
                        return
                    }
                }

                var privilegedDeleted: UInt64 = 0
                var privilegedFailed: UInt64 = 0
                if !parts.privilegedEntries.isEmpty {
                    if helperReady {
                        progressCurrent = "特权助手删除系统路径…"
                        do {
                            try await PrivilegedApply.applyPrivilegedPaths(
                                parts.privilegedEntries.map(\.path)
                            )
                            privilegedDeleted = UInt64(parts.privilegedEntries.count)
                        } catch {
                            privilegedFailed = UInt64(parts.privilegedEntries.count)
                            errorMessage = "特权助手：\(error.localizedDescription)"
                        }
                    } else {
                        helperDegradeNote =
                            "已跳过 \(parts.privilegedEntries.count) 项系统路径（特权助手未启用）。用户域清理不受影响。"
                    }
                }

                cleanupFullPlan()
                var merged = sidecarReport ?? VoleReport(
                    succeeded: 0,
                    skipped: 0,
                    failed: 0,
                    skippedByReason: [],
                    trashedBytes: 0,
                    deletedBytes: 0,
                    coverageNote: filtered.coverageNote
                )
                merged.succeeded += privilegedDeleted
                merged.failed += privilegedFailed
                if let note = helperDegradeNote {
                    merged.skipped += UInt64(parts.privilegedEntries.count)
                    let existing = merged.coverageNote.map { $0 + "\n" } ?? ""
                    merged.coverageNote = existing + note
                }
                report = merged
                phase = .result
            } catch {
                errorMessage = error.localizedDescription
                phase = .candidates
            }
        }
    }

    func reset() {
        cleanupFullPlan()
        fullPlan = nil
        phase = .idle
        entries = []
        selectedIDs = []
        report = nil
        errorMessage = nil
        coverageNote = nil
        helperDegradeNote = nil
    }

    private func handleStreamLine(_ line: String) {
        guard let event = try? VoleStreamEvent.decodeNDJSONLine(line) else { return }
        switch event {
        case let .progress(scanned, current):
            progressScanned = scanned
            progressCurrent = current
        case .candidate, .skipped, .done, .aborted:
            break
        }
    }

    private func handlePlanExit(_ exit: SidecarExit, planURL: URL) async {
        switch exit {
        case .success:
            do {
                let plan = try PlanIO.read(from: planURL)
                fullPlan = plan
                coverageNote = plan.coverageNote
                entries = plan.entries.filter { $0.skipReason == nil }
                selectedIDs = Set(entries.map(\.id))
                phase = .candidates
            } catch {
                cleanupFullPlan()
                errorMessage = "无法读取 plan: \(error.localizedDescription)"
                phase = .idle
            }
        case .cancelled:
            cleanupFullPlan()
            phase = .idle
        case .failed(let message):
            cleanupFullPlan()
            errorMessage = message
            if message.localizedCaseInsensitiveContains("permission")
                || message.localizedCaseInsensitiveContains("tcc")
                || message.contains("Operation not permitted") {
                showFDAAlert = true
            }
            phase = .idle
        }
    }

    private func cleanupFullPlan() {
        if let url = fullPlanURL {
            try? FileManager.default.removeItem(at: url)
        }
        fullPlanURL = nil
    }
}
