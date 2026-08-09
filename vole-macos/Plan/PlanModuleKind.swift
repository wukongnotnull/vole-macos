import Foundation

enum PlanModuleKind: String, CaseIterable, Identifiable {
    case uninstall
    case optimize

    var id: String { rawValue }

    var command: String { rawValue }

    var title: String {
        switch self {
        case .uninstall: return "卸载"
        case .optimize: return "优化"
        }
    }

    var idleHeadline: String {
        switch self {
        case .uninstall: return "挖出残留应用"
        case .optimize: return "松土优化系统"
        }
    }

    var idleCaption: String {
        switch self {
        case .uninstall: return "扫描可卸载应用与用户域残留"
        case .optimize: return "扫描可执行的优化任务"
        }
    }

    var scanEyebrow: String { "Scanning · 扫描中" }
    var scanTitle: String { "正在翻找" }

    var candidatesEyebrow: String { "Candidates · 候选" }
    var candidatesTitle: String {
        switch self {
        case .uninstall: return "挑要卸载的"
        case .optimize: return "挑要执行的"
        }
    }

    var applyEyebrow: String {
        switch self {
        case .uninstall: return "Applying · 卸载中"
        case .optimize: return "Applying · 优化中"
        }
    }

    var applyTitle: String {
        switch self {
        case .uninstall: return "正在卸载"
        case .optimize: return "正在优化"
        }
    }

    var applyHint: String {
        switch self {
        case .uninstall:
            return "个人文件移到废纸篓；需管理员权限的文件经 root权限助手永久删除。"
        case .optimize:
            return "删除类进废纸篓；动作类直接执行；需管理员权限的文件经 root权限助手。"
        }
    }

    var primaryActionTitle: String {
        switch self {
        case .uninstall: return "卸载所选"
        case .optimize: return "执行所选"
        }
    }

    var confirmTitle: String {
        switch self {
        case .uninstall:
            return "个人文件移到废纸篓；需管理员权限的文件经 root权限助手永久删除（未就绪则跳过）"
        case .optimize:
            return "将执行已选优化任务（删除类进废纸篓；root权限助手未就绪则跳过需管理员权限的文件）"
        }
    }

    var confirmButton: String {
        switch self {
        case .uninstall: return "确认卸载"
        case .optimize: return "确认执行"
        }
    }

    var resultTitle: String {
        switch self {
        case .uninstall: return "卸载完成"
        case .optimize: return "优化完成"
        }
    }

    var planFilePrefix: String { "\(rawValue)-full" }
    var applyFilePrefix: String { "\(rawValue)-apply" }
}
