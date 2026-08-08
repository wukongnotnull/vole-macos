import SwiftUI

struct HelperStatusCard: View {
    @ObservedObject var model: HelperStatusModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("特权助手").font(.headline)
            Text("系统路径永久删除与 launchd unload 需要批准一次后台项。用户域清理仍走 sidecar。")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Text("状态：\(model.statusText)")
                if let ping = model.lastPing {
                    Text("· ping pid=\(ping.pid) uid=\(ping.uid)")
                        .foregroundStyle(ping.uid == 0 ? Color.secondary : Color.orange)
                }
            }
            .font(.caption)
            if let error = model.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            HStack {
                Button(model.isReady ? "重新检查" : "启用特权助手") {
                    if model.isReady {
                        Task { await model.ping() }
                    } else {
                        model.registerAndGuide()
                    }
                }
                .disabled(model.isBusy)
                if model.status == .requiresApproval {
                    Button("打开系统设置") { model.openSettings() }
                }
                if model.isReady {
                    Button("注销", role: .destructive) { model.unregister() }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onAppear {
            model.refresh()
            if model.isReady {
                Task { await model.ping() }
            }
        }
    }
}
