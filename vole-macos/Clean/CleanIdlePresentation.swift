import Foundation

/// Copy and status labels for Clean idle — unit-tested, view-agnostic.
enum CleanIdlePresentation {
    static let soilCaption = "可回收层 · 待扫描"
    static let helperTitle = "系统级清理"
    static let supportingCopy = "先扫描用户缓存与可安全清理的文件；系统路径需开启特权助手。"

    static func helperDetail(status: HelperRegistrationStatus) -> String {
        switch status {
        case .notRegistered:
            return "特权助手 · 未启用"
        case .enabled:
            return "特权助手 · 已启用"
        case .requiresApproval:
            return "特权助手 · 待系统设置批准"
        case .notFound:
            return "特权助手 · 构建缺 Helper"
        case .unknown:
            return "特权助手 · 未知"
        }
    }

    static func fdaCaption(denied: Bool) -> String {
        denied ? "FDA · 未授权" : "FDA · 已授权"
    }
}
