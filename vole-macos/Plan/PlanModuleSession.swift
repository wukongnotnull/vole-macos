import Foundation
import Combine

@MainActor
final class PlanModuleSession: ObservableObject {
    enum Phase: Equatable {
        case idle
        case scanning
        case candidates
        case applying
        case result
    }

    let kind: PlanModuleKind

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
    @Published var permanentDelete: Bool = false

    private var process = VoleProcess()
    private var fullPlanURL: URL?
    private var fullPlan: VolePlan?

    init(kind: PlanModuleKind) {
        self.kind = kind
    }

    nonisolated static func applyArguments(command: String, planPath: String, permanent: Bool) -> [String] {
        var args = [command, "--apply", planPath, "--json-stream"]
        if permanent {
            args.append("--permanent")
        }
        return args
    }

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
                let planURL = dir.appendingPathComponent("\(kind.planFilePrefix)-\(UUID().uuidString).json")
                fullPlanURL = planURL
                let exit = await process.run(arguments: [
                    kind.command, "--plan", "--json-stream", "--plan-out", planURL.path,
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
        progressScanned = 0
        progressCurrent = ""
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
                    let applyURL = dir.appendingPathComponent(
                        "\(kind.applyFilePrefix)-\(UUID().uuidString).json"
                    )
                    try PlanIO.write(userPlan, to: applyURL)
                    defer { try? FileManager.default.removeItem(at: applyURL) }

                    let reportBox = ReportBox()
                    let permanent = permanentDelete && kind.supportsPermanentDelete
                    let exit = await process.run(arguments: Self.applyArguments(
                        command: kind.command,
                        planPath: applyURL.path,
                        permanent: permanent
                    )) { [weak self] line in
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
                        errorMessage = "已取消（可能已部分执行）"
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
                        progressCurrent = "root权限助手正在删除需管理员权限的文件…"
                        do {
                            try await PrivilegedApply.applyPrivilegedPaths(
                                parts.privilegedEntries.map(\.path)
                            )
                            privilegedDeleted = UInt64(parts.privilegedEntries.count)
                        } catch {
                            privilegedFailed = UInt64(parts.privilegedEntries.count)
                            errorMessage = "root权限助手：\(error.localizedDescription)"
                        }
                    } else {
                        helperDegradeNote =
                            "已跳过 \(parts.privilegedEntries.count) 项需管理员权限的文件（root权限助手未启用）。个人文件操作不受影响。"
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
