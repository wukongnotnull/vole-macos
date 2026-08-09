import Foundation
import Combine

@MainActor
final class HistorySession: ObservableObject {
    static let minLimit: UInt = 1
    static let maxLimit: UInt = 200
    static let defaultLimit: UInt = 20

    @Published var limit: UInt = HistorySession.defaultLimit
    @Published var snapshot: HistorySnapshot?
    @Published var errorMessage: String?
    @Published var isRefreshing = false

    private var process = VoleProcess()

    var clampedLimit: UInt {
        min(max(limit, Self.minLimit), Self.maxLimit)
    }

    func refresh() {
        limit = clampedLimit
        isRefreshing = true
        errorMessage = nil
        Task {
            let linesBox = LinesBox()
            let exit = await process.run(arguments: [
                "history", "--json", "--limit", "\(clampedLimit)",
            ]) { line in
                linesBox.append(line)
            }
            isRefreshing = false
            switch exit {
            case .success:
                let joined = linesBox.joinedUTF8().trimmingCharacters(in: .whitespacesAndNewlines)
                guard !joined.isEmpty else {
                    errorMessage = "history 无输出"
                    return
                }
                do {
                    snapshot = try HistorySnapshot.decode(fromJSONLine: joined)
                } catch {
                    errorMessage = "无法解析 history：\(error.localizedDescription)"
                }
            case .cancelled:
                break
            case .failed(let message):
                errorMessage = message
            }
        }
    }
}
