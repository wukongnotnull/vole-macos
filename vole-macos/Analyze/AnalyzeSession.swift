import Foundation
import AppKit
import Combine

@MainActor
final class AnalyzeSession: ObservableObject {
    @Published var pathStack: [String]
    @Published var entries: [AnalyzeEntryItem] = []
    @Published var largeFiles: [AnalyzeFileItem] = []
    @Published var totalSize: Int64 = 0
    @Published var totalFiles: Int64?
    @Published var isScanning = false
    @Published var errorMessage: String?

    private var process = VoleProcess()

    var currentPath: String {
        pathStack.last ?? NSHomeDirectory()
    }

    var canGoUp: Bool {
        pathStack.count > 1
    }

    init(root: String = NSHomeDirectory()) {
        pathStack = [root]
    }

    func rescan() {
        let path = currentPath
        isScanning = true
        errorMessage = nil
        Task {
            let linesBox = LinesBox()
            let exit = await process.run(arguments: ["analyze", "--json", path]) { line in
                linesBox.append(line)
            }
            isScanning = false
            switch exit {
            case .success:
                let joined = linesBox.joinedUTF8().trimmingCharacters(in: .whitespacesAndNewlines)
                guard !joined.isEmpty else {
                    errorMessage = "analyze 无输出"
                    return
                }
                do {
                    let snap = try AnalyzeSnapshot.decode(fromJSONLine: joined)
                    entries = snap.entries
                    largeFiles = snap.largeFiles
                    totalSize = snap.totalSize
                    totalFiles = snap.totalFiles
                } catch {
                    errorMessage = "无法解析 analyze：\(error.localizedDescription)"
                }
            case .cancelled:
                break
            case .failed(let message):
                errorMessage = message
            }
        }
    }

    func enterDirectory(_ path: String) {
        guard !isScanning else { return }
        pathStack.append(path)
        rescan()
    }

    func goUp() {
        guard canGoUp, !isScanning else { return }
        pathStack.removeLast()
        rescan()
    }

    func cancel() {
        Task { await process.cancel() }
    }

    func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: currentPath, isDirectory: true)
        panel.prompt = "选择"
        panel.message = "选择要分析的目录"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        pathStack = [url.path]
        rescan()
    }

    func scanRoot(_ path: String) {
        pathStack = [path]
        rescan()
    }
}
