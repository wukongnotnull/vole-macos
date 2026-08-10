import SwiftUI

/// Light-content helper toggle for Clean idle (system-path cleanup).
struct HelperStatusCard: View {
    @ObservedObject var model: HelperStatusModel

    var body: some View {
        HStack(alignment: .center, spacing: VoleTheme.Spacing.md) {
            Image(systemName: iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 22, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(CleanIdlePresentation.helperTitle)
                    .font(VoleTheme.TypeScale.headline())
                    .foregroundStyle(VoleTheme.Colors.text)
                Text(CleanIdlePresentation.helperDetail(status: model.status))
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Toggle(
                CleanIdlePresentation.helperTitle,
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
            .tint(VoleTheme.Colors.soil)
            .disabled(model.isBusy)
            .accessibilityLabel(CleanIdlePresentation.helperTitle)
            .accessibilityValue(model.isReady ? "已开启" : "已关闭")
        }
        .padding(.horizontal, VoleTheme.Spacing.md)
        .padding(.vertical, VoleTheme.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(VoleTheme.Colors.molehill.opacity(0.28))
        .clipShape(RoundedRectangle(cornerRadius: VoleTheme.Radius.control))
        .overlay(
            RoundedRectangle(cornerRadius: VoleTheme.Radius.control)
                .strokeBorder(
                    VoleTheme.Colors.molehill,
                    style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                )
        )
        .help(helpText)
        .onAppear {
            model.refresh()
            if model.isReady {
                Task { await model.ping() }
            }
        }
    }

    private var iconName: String {
        if model.isReady { return "checkmark.shield.fill" }
        if model.status == .requiresApproval { return "hand.raised.fill" }
        return "lock.shield"
    }

    private var iconColor: Color {
        if model.isReady { return VoleTheme.Colors.sage }
        if model.status == .requiresApproval { return VoleTheme.Colors.fur }
        return VoleTheme.Colors.soil.opacity(0.85)
    }

    private var helpText: String {
        if model.isReady {
            return "关闭特权助手后，系统路径清理将跳过"
        }
        return "启用特权助手，以便清理需要管理员权限的系统路径"
    }
}
