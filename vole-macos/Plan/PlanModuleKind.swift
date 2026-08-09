import Foundation

enum PlanModuleKind: String, CaseIterable, Identifiable {
    case uninstall
    case optimize
    case purge
    case installer

    var id: String { rawValue }

    var command: String { rawValue }

    var supportsPermanentDelete: Bool {
        switch self {
        case .purge, .installer: return true
        case .uninstall, .optimize: return false
        }
    }

    var title: String {
        switch self {
        case .uninstall: return "卸载"
        case .optimize: return "优化"
        case .purge: return "净化"
        case .installer: return "安装包"
        }
    }

    var idleEyebrow: String {
        switch self {
        case .uninstall: return "Uninstall · 卸载"
        case .optimize: return "Optimize · 优化"
        case .purge: return "Purge · 净化"
        case .installer: return "Installer · 安装包"
        }
    }

    var idleHeadline: String {
        switch self {
        case .uninstall: return "挖出残留应用"
        case .optimize: return "松土优化系统"
        case .purge: return "挖出陈旧构建物"
        case .installer: return "找出安装包"
        }
    }

    var idleCaption: String {
        switch self {
        case .uninstall: return "扫描可卸载应用与用户域残留"
        case .optimize: return "扫描可执行的优化任务"
        case .purge: return "扫描陈旧项目构建物"
        case .installer: return "扫描可清理的安装包"
        }
    }

    var scanEyebrow: String { "Scanning · 扫描中" }
    var scanTitle: String { "正在翻找" }

    var candidatesEyebrow: String { "Candidates · 候选" }
    var candidatesTitle: String {
        switch self {
        case .uninstall: return "挑要卸载的"
        case .optimize: return "挑要执行的"
        case .purge: return "挑要净化的"
        case .installer: return "挑要清理的"
        }
    }

    var applyEyebrow: String {
        switch self {
        case .uninstall: return "Applying · 卸载中"
        case .optimize: return "Applying · 优化中"
        case .purge: return "Applying · 净化中"
        case .installer: return "Applying · 清理中"
        }
    }

    var applyTitle: String {
        switch self {
        case .uninstall: return "正在卸载"
        case .optimize: return "正在优化"
        case .purge: return "正在净化"
        case .installer: return "正在清理安装包"
        }
    }

    var applyHint: String {
        switch self {
        case .uninstall:
            return "个人文件移到废纸篓；需管理员权限的文件经 root权限助手永久删除。"
        case .optimize:
            return "删除类进废纸篓；动作类直接执行；需管理员权限的文件经 root权限助手。"
        case .purge:
            return "默认进废纸篓；开启永久删除则直接删除；需管理员权限的文件经 root权限助手。"
        case .installer:
            return "默认进废纸篓；开启永久删除则直接删除；需管理员权限的文件经 root权限助手。"
        }
    }

    var primaryActionTitle: String {
        switch self {
        case .uninstall: return "卸载所选"
        case .optimize: return "执行所选"
        case .purge: return "净化所选"
        case .installer: return "清理所选"
        }
    }

    func confirmTitle(permanentDelete: Bool) -> String {
        let base: String
        switch self {
        case .uninstall:
            base = "个人文件移到废纸篓；需管理员权限的文件经 root权限助手永久删除（未就绪则跳过）"
        case .optimize:
            base = "将执行已选优化任务（删除类进废纸篓；root权限助手未就绪则跳过需管理员权限的文件）"
        case .purge:
            base = "将净化已选构建物（默认进废纸篓；需管理员权限的文件经 root权限助手，未就绪则跳过）"
        case .installer:
            base = "将清理已选安装包（默认进废纸篓；需管理员权限的文件经 root权限助手，未就绪则跳过）"
        }
        if permanentDelete && supportsPermanentDelete {
            return base + "。将永久删除，不可从废纸篓恢复"
        }
        return base
    }

    var confirmButton: String {
        switch self {
        case .uninstall: return "确认卸载"
        case .optimize: return "确认执行"
        case .purge: return "确认净化"
        case .installer: return "确认清理"
        }
    }

    var resultTitle: String {
        switch self {
        case .uninstall: return "卸载完成"
        case .optimize: return "优化完成"
        case .purge: return "净化完成"
        case .installer: return "安装包清理完成"
        }
    }

    var planFilePrefix: String { "\(rawValue)-full" }
    var applyFilePrefix: String { "\(rawValue)-apply" }
}
