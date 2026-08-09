import Foundation

enum ShellModule: String, CaseIterable, Identifiable {
    case clean, uninstall, optimize, purge, installer, analyze, history, status

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clean: return "清理"
        case .uninstall: return "卸载"
        case .optimize: return "优化"
        case .purge: return "净化"
        case .installer: return "安装包"
        case .analyze: return "分析"
        case .history: return "历史"
        case .status: return "状态"
        }
    }

    var isAvailable: Bool { true }

    var systemImage: String {
        switch self {
        case .clean: return "sparkles"
        case .uninstall: return "trash"
        case .optimize: return "gauge"
        case .purge: return "flame"
        case .installer: return "shippingbox"
        case .analyze: return "chart.pie"
        case .history: return "clock"
        case .status: return "chart.bar"
        }
    }
}
