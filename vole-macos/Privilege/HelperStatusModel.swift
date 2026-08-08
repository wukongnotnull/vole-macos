import Combine
import Foundation

@MainActor
final class HelperStatusModel: ObservableObject {
    @Published var status: HelperRegistrationStatus = .unknown("uninitialized")
    @Published var lastPing: (pid: Int32, uid: Int32)?
    @Published var lastError: String?
    @Published var isBusy = false

    var isReady: Bool { status.isReadyForXPC }

    var statusText: String {
        switch status {
        case .notRegistered: return "未注册"
        case .enabled: return "已启用"
        case .requiresApproval: return "待系统设置批准"
        case .notFound: return "Bundle 缺少 Helper（构建问题）"
        case .unknown(let raw): return "未知（\(raw)）"
        }
    }

    func refresh() {
        status = HelperRegistration.currentStatus()
    }

    func registerAndGuide() {
        isBusy = true
        lastError = nil
        defer {
            isBusy = false
            refresh()
        }
        do {
            let next = try HelperRegistration.register()
            status = next
            if next == .requiresApproval {
                HelperRegistration.openSystemSettings()
            } else if next == .enabled {
                Task { await ping() }
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func openSettings() {
        HelperRegistration.openSystemSettings()
    }

    func ping() async {
        isBusy = true
        lastError = nil
        defer { isBusy = false }
        refresh()
        do {
            let result = try await HelperXPCClient.ping()
            lastPing = result
            if result.uid != 0 {
                lastError = "Helper ping 返回 uid=\(result.uid)，期望 uid=0（未以 root 运行）"
            }
        } catch {
            lastPing = nil
            lastError = error.localizedDescription
        }
    }

    func unregister() {
        isBusy = true
        lastError = nil
        defer {
            isBusy = false
            refresh()
        }
        do {
            try HelperRegistration.unregister()
            lastPing = nil
        } catch {
            lastError = error.localizedDescription
        }
    }
}
