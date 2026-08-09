import Foundation
import Combine

@MainActor
final class StatusSession: ObservableObject {
    @Published var snapshot: StatusSnapshot?
    @Published var errorMessage: String?
    @Published var isRefreshing = false
    @Published var isLive = false
    @Published var voleVersion: String = ""

    private var process = VoleProcess()
    private var liveTask: Task<Void, Never>?

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

    func refreshOnce() {
        Task { await runStatusOnce() }
    }

    func startLive(intervalSeconds: TimeInterval = 3) {
        guard !isLive else { return }
        isLive = true
        liveTask?.cancel()
        liveTask = Task { [weak self] in
            while let self, !Task.isCancelled, self.isLive {
                await self.runStatusOnce()
                try? await Task.sleep(nanoseconds: UInt64(intervalSeconds * 1_000_000_000))
            }
        }
    }

    func stopLive() {
        isLive = false
        liveTask?.cancel()
        liveTask = nil
        Task { await process.cancel() }
    }

    private func runStatusOnce() async {
        isRefreshing = true
        errorMessage = nil
        let linesBox = LinesBox()
        let exit = await process.run(arguments: ["status", "--json"]) { line in
            linesBox.append(line)
        }
        isRefreshing = false
        switch exit {
        case .success:
            let joined = linesBox.joinedUTF8().trimmingCharacters(in: .whitespacesAndNewlines)
            guard !joined.isEmpty else {
                errorMessage = "status 无输出"
                return
            }
            do {
                snapshot = try StatusSnapshot.decode(fromJSONLine: joined)
            } catch {
                errorMessage = "无法解析 status：\(error.localizedDescription)"
            }
        case .cancelled:
            break
        case .failed(let message):
            errorMessage = message
        }
    }
}
