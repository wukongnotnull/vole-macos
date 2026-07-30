import Foundation
import Combine

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

    private var process = VoleProcess()
    private var fullPlanURL: URL?
    private var fullPlan: VolePlan?

    func refreshVersion() {
        Task {
            let proc = VoleProcess()
            var lines: [String] = []
            let exit = await proc.run(arguments: ["--version"]) { line in
                lines.append(line)
            }
            if case .success = exit {
                voleVersion = lines.last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            }
        }
    }

    func startScan() {
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
        guard let fullPlan else {
            errorMessage = "缺少 plan，请重新扫描"
            return
        }
        if PlanIO.isExpired(fullPlan) {
            errorMessage = "计划已过期，请重新扫描"
            phase = .idle
            return
        }
        let filtered = PlanIO.filter(plan: fullPlan, selectedIDs: selectedIDs)
        guard !filtered.entries.isEmpty else {
            errorMessage = "请至少选择一项"
            return
        }
        phase = .applying
        errorMessage = nil

        Task {
            do {
                let dir = try PlanIO.cachesDirectory()
                let applyURL = dir.appendingPathComponent("clean-apply-\(UUID().uuidString).json")
                try PlanIO.write(filtered, to: applyURL)
                defer { try? FileManager.default.removeItem(at: applyURL) }

                var lastReport: VoleReport?
                let exit = await process.run(arguments: [
                    "clean", "--apply", applyURL.path, "--json-stream",
                ]) { [weak self] line in
                    Task { @MainActor in
                        if let event = try? VoleStreamEvent.decodeNDJSONLine(line) {
                            if case let .done(report) = event {
                                lastReport = report
                            }
                            if case let .progress(scanned, current) = event {
                                self?.progressScanned = scanned
                                self?.progressCurrent = current
                            }
                        }
                    }
                }
                cleanupFullPlan()
                switch exit {
                case .success:
                    report = lastReport
                    phase = .result
                case .cancelled:
                    errorMessage = "已取消（可能已部分清理）"
                    report = lastReport
                    phase = .result
                case .failed(let message):
                    errorMessage = message
                    phase = .candidates
                }
            } catch {
                errorMessage = error.localizedDescription
                phase = .candidates
            }
        }
    }

    func reset() {
        cleanupFullPlan()
        phase = .idle
        entries = []
        selectedIDs = []
        report = nil
        errorMessage = nil
        coverageNote = nil
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
