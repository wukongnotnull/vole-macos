import Foundation
import Combine

struct TouchIdStatusJSON: Codable, Equatable {
    var configured: Bool
    var pamTidLine: String?
    var usesSudoLocal: Bool?
}

struct UpdateCheckJSON: Codable, Equatable {
    var channel: String?
    var current: String?
    var latest: String?
    var origin: String?
    var outcome: String?
    var message: String?
}

struct RemovePreviewJSON: Codable, Equatable {
    var homebrew: Bool?
    var items: [RemovePreviewItem]
    var status: String?
}

struct RemovePreviewItem: Codable, Equatable, Identifiable {
    var kind: String
    var note: String?
    var path: String

    var id: String { "\(kind)-\(path)" }
}

@MainActor
final class SettingsToolsModel: ObservableObject {
    @Published var touchIdConfigured: Bool?
    @Published var touchIdMessage: String = ""
    @Published var touchIdBusy = false

    @Published var updateCheck: UpdateCheckJSON?
    @Published var updateMessage: String = ""
    @Published var updateBusy = false

    @Published var removeItems: [RemovePreviewItem] = []
    @Published var removeHomebrew = false
    @Published var removeMessage: String = ""
    @Published var removeBusy = false
    @Published var purgeOplog = false

    private var process = VoleProcess()

    nonisolated static func touchIdArgs(action: String) -> [String] {
        ["touchid", action, "--json"]
    }

    nonisolated static func updateCheckArgs() -> [String] {
        ["update", "--check", "--json"]
    }

    nonisolated static func updateApplyArgs(force: Bool, nightly: Bool) -> [String] {
        var args = ["update", "--yes", "--json"]
        if force { args.append("--force") }
        if nightly { args.append("--nightly") }
        return args
    }

    nonisolated static func removeDryRunArgs(purgeOplog: Bool) -> [String] {
        var args = ["remove", "--dry-run", "--json"]
        if purgeOplog { args.append("--purge-oplog") }
        return args
    }

    nonisolated static func removeApplyArgs(purgeOplog: Bool) -> [String] {
        var args = ["remove", "--yes", "--json"]
        if purgeOplog { args.append("--purge-oplog") }
        return args
    }

    func refreshTouchId() {
        touchIdBusy = true
        touchIdMessage = ""
        Task {
            let result = await runJSON(Self.touchIdArgs(action: "status"))
            touchIdBusy = false
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let status = try decoder.decode(TouchIdStatusJSON.self, from: data)
                    touchIdConfigured = status.configured
                    touchIdMessage = status.configured ? "已配置 pam_tid" : "未配置"
                } catch {
                    touchIdMessage = "无法解析 touchid：\(error.localizedDescription)"
                }
            case .failure(let message):
                touchIdMessage = message
            }
        }
    }

    func enableTouchId() {
        runTouchIdAction("enable")
    }

    func disableTouchId() {
        runTouchIdAction("disable")
    }

    private func runTouchIdAction(_ action: String) {
        touchIdBusy = true
        touchIdMessage = ""
        Task {
            let result = await runJSON(Self.touchIdArgs(action: action))
            touchIdBusy = false
            switch result {
            case .success:
                refreshTouchId()
            case .failure(let message):
                touchIdMessage = message
            }
        }
    }

    func checkForUpdate() {
        updateBusy = true
        updateMessage = ""
        Task {
            let result = await runJSON(Self.updateCheckArgs())
            updateBusy = false
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    updateCheck = try decoder.decode(UpdateCheckJSON.self, from: data)
                    if let current = updateCheck?.current, let latest = updateCheck?.latest {
                        updateMessage = "当前 \(current) · 最新 \(latest) · 来源 \(updateCheck?.origin ?? "?")"
                    }
                } catch {
                    updateMessage = "无法解析 update：\(error.localizedDescription)"
                }
            case .failure(let message):
                updateMessage = message
            }
        }
    }

    func runUpdate(force: Bool = false, nightly: Bool = false) {
        updateBusy = true
        updateMessage = ""
        Task {
            let result = await runJSON(Self.updateApplyArgs(force: force, nightly: nightly))
            updateBusy = false
            switch result {
            case .success:
                updateMessage = "更新完成，请刷新版本"
                checkForUpdate()
            case .failure(let message):
                updateMessage = message
            }
        }
    }

    func previewRemove() {
        removeBusy = true
        removeMessage = ""
        Task {
            let result = await runJSON(Self.removeDryRunArgs(purgeOplog: purgeOplog))
            removeBusy = false
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let preview = try decoder.decode(RemovePreviewJSON.self, from: data)
                    removeItems = preview.items
                    removeHomebrew = preview.homebrew ?? false
                    if removeHomebrew {
                        removeMessage = "检测到 Homebrew 安装，建议使用 brew uninstall"
                    } else if removeItems.isEmpty {
                        removeMessage = "无可删除项"
                    } else {
                        removeMessage = "预览 \(removeItems.count) 项"
                    }
                } catch {
                    removeMessage = "无法解析 remove：\(error.localizedDescription)"
                }
            case .failure(let message):
                removeMessage = message
            }
        }
    }

    func confirmRemove() {
        removeBusy = true
        removeMessage = ""
        Task {
            let result = await runJSON(Self.removeApplyArgs(purgeOplog: purgeOplog))
            removeBusy = false
            switch result {
            case .success:
                removeMessage = "自卸载已执行；可能需要退出 App"
                removeItems = []
            case .failure(let message):
                removeMessage = message
            }
        }
    }

    private enum JSONResult {
        case success(Data)
        case failure(String)
    }

    private func runJSON(_ arguments: [String]) async -> JSONResult {
        let linesBox = LinesBox()
        let exit = await process.run(arguments: arguments) { line in
            linesBox.append(line)
        }
        switch exit {
        case .success:
            let joined = linesBox.joinedUTF8().trimmingCharacters(in: .whitespacesAndNewlines)
            guard let data = joined.data(using: .utf8), !joined.isEmpty else {
                return .failure("无 JSON 输出")
            }
            return .success(data)
        case .cancelled:
            return .failure("已取消")
        case .failed(let message):
            return .failure(message)
        }
    }
}
