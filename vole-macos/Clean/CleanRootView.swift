import SwiftUI

struct CleanRootView: View {
    @ObservedObject var session: CleanSession

    var body: some View {
        Group {
            switch session.phase {
            case .idle: CleanIdleView(session: session)
            case .scanning: CleanScanningView(session: session)
            case .candidates: CleanCandidatesView(session: session)
            case .applying: CleanApplyingView(session: session)
            case .result: CleanResultView(session: session)
            }
        }
        .frame(minWidth: 520, minHeight: 420)
        .padding()
        .alert("需要完全磁盘访问", isPresented: $session.showFDAAlert) {
            Button("打开系统设置") { FDAProbe.openSettings() }
            Button("稍后", role: .cancel) {}
        } message: {
            Text("未授权时扫描结果可能偏少。请在「隐私与安全性 → 完全磁盘访问」中勾选 vole-macos。")
        }
        .onAppear { session.refreshVersion() }
    }
}
