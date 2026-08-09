import SwiftUI

/// Compact root-helper control for the dark sidebar footer.
struct SidebarRootHelperRow: View {
    @ObservedObject var model: HelperStatusModel

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.xs) {
            HStack(spacing: VoleTheme.Spacing.sm) {
                Image(systemName: iconName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 18, alignment: .center)

                Text("root")
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(VoleTheme.Colors.onInk.opacity(0.72))

                Spacer(minLength: 0)

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
                .controlSize(.mini)
                .tint(VoleTheme.Colors.sage)
                .disabled(model.isBusy)
                .accessibilityLabel("root权限助手")
                .accessibilityValue(model.isReady ? "已开启" : "已关闭")
            }

            if model.status == .requiresApproval {
                Button("待批准 · 打开设置") { model.openSettings() }
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(VoleTheme.Colors.fur)
                    .buttonStyle(.plain)
            } else if let hint = attentionHint {
                Text(hint)
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(VoleTheme.Colors.onInk.opacity(0.45))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, VoleTheme.Spacing.sm)
        .padding(.vertical, VoleTheme.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .help(helpText)
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
        if model.status == .requiresApproval { return VoleTheme.Colors.fur }
        return VoleTheme.Colors.onInk.opacity(0.55)
    }

    private var attentionHint: String? {
        if let error = model.lastError, !error.isEmpty {
            return error
        }
        switch model.status {
        case .notFound:
            return "构建缺 Helper"
        case .unknown:
            return model.statusText
        default:
            return nil
        }
    }

    private var helpText: String {
        if model.isReady {
            return "关闭 root权限助手"
        }
        return "启用 root权限助手，以便清理需要管理员权限的文件"
    }
}
