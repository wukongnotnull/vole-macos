import Foundation

enum ShellModule: String, CaseIterable, Identifiable {
    case clean, uninstall, optimize, purge, installer, worktree, agent, analyze, history, status

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clean: return "清理"
        case .uninstall: return "卸载"
        case .optimize: return "优化"
        case .purge: return "净化"
        case .installer: return "安装包"
        case .worktree: return "Worktree"
        case .agent: return "Agent"
        case .analyze: return "分析"
        case .history: return "历史"
        case .status: return "状态"
        }
    }

    func isAvailable(sidecarVersion: String) -> Bool {
        switch self {
        case .worktree, .agent:
            return SidecarVersion.supportsWorktreeAgent(sidecarVersion)
        case .clean, .uninstall, .optimize, .purge, .installer, .analyze, .history, .status:
            return true
        }
    }

    func sidebarHelp(sidecarVersion: String) -> String {
        if isAvailable(sidecarVersion: sidecarVersion) {
            return title
        }
        return "\(title) · 需要内嵌 vole 2.20"
    }

    var systemImage: String {
        switch self {
        case .clean: return "sparkles"
        case .uninstall: return "trash"
        case .optimize: return "gauge"
        case .purge: return "flame"
        case .installer: return "shippingbox"
        case .worktree: return "arrow.triangle.branch"
        case .agent: return "cpu"
        case .analyze: return "chart.pie"
        case .history: return "clock"
        case .status: return "chart.bar"
        }
    }
}
