import SwiftUI

/// Compact system-path helper strip — status by icon, on/off by toggle.
struct HelperStatusCard: View {
    @ObservedObject var model: HelperStatusModel

    var body: some View {
        HStack(spacing: VoleTheme.Spacing.sm) {
            Image(systemName: iconName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 20)

            Text("系统级清理")
                .font(VoleTheme.TypeScale.body())
                .foregroundStyle(VoleTheme.Colors.text)

            if let hint = compactHint {
                Text(hint)
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(VoleTheme.Colors.soil)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: VoleTheme.Spacing.sm)

            if model.status == .requiresApproval {
                Button("批准") { model.openSettings() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }

            if model.isReady {
                Button("检测状态") {
                    Task { await model.ping() }
                }
                .buttonStyle(.bordered)
                .tint(VoleTheme.Colors.soil)
                .controlSize(.small)
                .disabled(model.isBusy)
                .help("检测 root权限助手是否在线")
            }

            Toggle(
                "root权限助手",
                isOn: Binding(
                    get: { model.isReady },
                    set: { on in
                        if on {
                            model.registerAndGuide()
                        } else {
                            model.unregister()
                        }
                    }
                )
            )
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.small)
            .tint(VoleTheme.Colors.sage)
            .disabled(model.isBusy)
            .help(
                model.isReady
                    ? "关闭 root权限助手"
                    : "启用 root权限助手，以便清理需要管理员权限的文件"
            )
            .accessibilityLabel("root权限助手")
            .accessibilityValue(model.isReady ? "已开启" : "已关闭")
        }
        .padding(.horizontal, VoleTheme.Spacing.md)
        .padding(.vertical, VoleTheme.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(VoleTheme.Colors.molehill.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: VoleTheme.Radius.control))
        .overlay(
            RoundedRectangle(cornerRadius: VoleTheme.Radius.control)
                .stroke(
                    VoleTheme.Colors.soil.opacity(0.35),
                    style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                )
        )
        .onAppear {
            model.refresh()
            if model.isReady {
                Task { await model.ping() }
            }
        }
    }

    private var iconName: String {
        if model.isReady { return "checkmark.seal.fill" }
        if model.status == .requiresApproval { return "hand.raised.fill" }
        return "lock.shield"
    }

    private var iconColor: Color {
        if model.isReady { return VoleTheme.Colors.sage }
        return VoleTheme.Colors.soil
    }

    /// Only show a one-line hint when something needs attention.
    private var compactHint: String? {
        if let error = model.lastError, !error.isEmpty {
            return error
        }
        switch model.status {
        case .notFound:
            return "构建缺 Helper"
        case .requiresApproval:
            return "待批准"
        case .unknown:
            return model.statusText
        default:
            return nil
        }
    }
}
