import SwiftUI

struct HelperStatusCard: View {
    @ObservedObject var model: HelperStatusModel

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.sm) {
            HStack(spacing: VoleTheme.Spacing.sm) {
                Image(systemName: model.isReady ? "checkmark.seal.fill" : "lock.shield")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(model.isReady ? VoleTheme.Colors.sage : VoleTheme.Colors.soil)
                Text("特权助手")
                    .font(VoleTheme.TypeScale.headline())
                    .foregroundStyle(VoleTheme.Colors.text)
                Spacer(minLength: 0)
                Text(model.isReady ? "已就绪" : "未启用")
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.secondary)
            }

            Text("清理系统路径前需批准一次后台项；用户域仍走 sidecar。")
                .font(VoleTheme.TypeScale.caption())
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if !model.isReady {
                Text(model.statusText)
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(VoleTheme.Colors.soil)
            } else if let ping = model.lastPing {
                Text("助手在线 · pid \(ping.pid)")
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.secondary)
            }

            if let error = model.lastError {
                Text(error)
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(Color(hex: 0xB54A3C))
            }

            HStack(spacing: VoleTheme.Spacing.sm) {
                Button(model.isReady ? "重新检查" : "启用特权助手") {
                    if model.isReady {
                        Task { await model.ping() }
                    } else {
                        model.registerAndGuide()
                    }
                }
                .buttonStyle(.bordered)
                .tint(VoleTheme.Colors.soil)
                .disabled(model.isBusy)

                if model.status == .requiresApproval {
                    Button("打开系统设置") { model.openSettings() }
                        .buttonStyle(.bordered)
                }
                if model.isReady {
                    Button("注销", role: .destructive) { model.unregister() }
                }
            }
        }
        .padding(VoleTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(VoleTheme.Colors.molehill.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: VoleTheme.Radius.control))
        .overlay(
            RoundedRectangle(cornerRadius: VoleTheme.Radius.control)
                .stroke(VoleTheme.Colors.molehill, lineWidth: 1)
        )
        .onAppear {
            model.refresh()
            if model.isReady {
                Task { await model.ping() }
            }
        }
    }
}
