import Foundation

enum ShellModule: String, CaseIterable, Identifiable {
    case clean, uninstall, optimize, status

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clean: return "清理"
        case .uninstall: return "卸载"
        case .optimize: return "优化"
        case .status: return "状态"
        }
    }

    var isAvailable: Bool { self == .clean }
}
