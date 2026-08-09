import SwiftUI

struct PlanModuleRootView: View {
    @ObservedObject var session: PlanModuleSession
    @ObservedObject var helperStatus: HelperStatusModel

    var body: some View {
        Group {
            switch session.phase {
            case .idle:
                PlanModuleIdleView(session: session, helperStatus: helperStatus)
            case .scanning:
                PlanModuleScanningView(session: session)
            case .candidates:
                PlanModuleCandidatesView(session: session, helperStatus: helperStatus)
            case .applying:
                PlanModuleApplyingView(session: session)
            case .result:
                PlanModuleResultView(session: session)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("需要完全磁盘访问", isPresented: $session.showFDAAlert) {
            Button("打开系统设置") { FDAProbe.openSettings() }
            Button("稍后", role: .cancel) {}
        } message: {
            Text("未授权时扫描结果可能偏少。请在「隐私与安全性 → 完全磁盘访问」中勾选 \(FDAProbe.displayAppName)。")
        }
        .onAppear {
            session.refreshVersion()
            helperStatus.refresh()
        }
    }
}
