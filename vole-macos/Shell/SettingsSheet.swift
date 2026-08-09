import SwiftUI

struct SettingsSheet: View {
    @ObservedObject var tools: SettingsToolsModel
    let voleVersion: String
    let onRefreshVersion: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var confirmUpdate = false
    @State private var confirmRemove = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VoleTheme.Spacing.md) {
                SettingsSheetHeader(onDone: { dismiss() })

                SettingsFDASection()

                SettingsTouchIdSection(tools: tools)

                SettingsUpdateSection(
                    tools: tools,
                    onConfirmInstall: { confirmUpdate = true }
                )

                SettingsRemoveSection(
                    tools: tools,
                    onConfirmRemove: { confirmRemove = true }
                )

                SettingsAboutSection(
                    voleVersion: voleVersion,
                    onRefreshVersion: onRefreshVersion
                )
            }
            .padding(VoleTheme.Spacing.lg)
        }
        .frame(minWidth: 440, minHeight: 480)
        .background(VoleTheme.Colors.contentBackground)
        .onAppear {
            onRefreshVersion()
            tools.refreshTouchId()
        }
        .confirmationDialog("确认安装更新？", isPresented: $confirmUpdate, titleVisibility: .visible) {
            Button("安装更新", role: .destructive) { tools.runUpdate() }
            Button("取消", role: .cancel) {}
        }
        .confirmationDialog(
            "确认自卸载？将删除本工具安装产物与自身配置。",
            isPresented: $confirmRemove,
            titleVisibility: .visible
        ) {
            Button("确认自卸载", role: .destructive) { tools.confirmRemove() }
            Button("取消", role: .cancel) {}
        }
    }
}

// MARK: - Header

private struct SettingsSheetHeader: View {
    let onDone: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Settings · 设置")
                    .voleEyebrowStyle()
                Text("工坊设置")
                    .voleTitleStyle()
                    .foregroundStyle(VoleTheme.Colors.text)
            }
            Spacer(minLength: VoleTheme.Spacing.sm)
            Button("完成", action: onDone)
                .buttonStyle(.borderedProminent)
                .tint(VoleTheme.Colors.soil)
                .controlSize(.small)
                .keyboardShortcut(.defaultAction)
        }
    }
}

// MARK: - Section chrome

private struct SettingsSectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.sm) {
            Text(title)
                .font(VoleTheme.TypeScale.headline())
                .foregroundStyle(VoleTheme.Colors.text)
            content()
        }
        .padding(.horizontal, VoleTheme.Spacing.md)
        .padding(.vertical, VoleTheme.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(VoleTheme.Colors.molehill.opacity(0.28))
        .clipShape(RoundedRectangle(cornerRadius: VoleTheme.Radius.control))
    }
}

private struct SettingsStatusRow<Trailing: View>: View {
    let systemImage: String
    let tint: Color
    let message: String
    @ViewBuilder var trailing: () -> Trailing

    init(
        systemImage: String,
        tint: Color,
        message: String,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.systemImage = systemImage
        self.tint = tint
        self.message = message
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .center, spacing: VoleTheme.Spacing.sm) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 18, alignment: .center)
            Text(message)
                .font(VoleTheme.TypeScale.body())
                .foregroundStyle(VoleTheme.Colors.text)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: VoleTheme.Spacing.sm)
            trailing()
        }
        .padding(.horizontal, VoleTheme.Spacing.sm)
        .padding(.vertical, VoleTheme.Spacing.xs)
        .background(tint.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: VoleTheme.Radius.strata))
    }
}

private struct SettingsActionRow<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(spacing: VoleTheme.Spacing.sm) {
            content()
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
}

// MARK: - Sections

private struct SettingsFDASection: View {
    private var denied: Bool { FDAProbe.looksDenied() }

    var body: some View {
        SettingsSectionCard(title: "完全磁盘访问") {
            VStack(alignment: .leading, spacing: VoleTheme.Spacing.xs) {
                SettingsStatusRow(
                    systemImage: denied ? "exclamationmark.triangle.fill" : "checkmark.seal.fill",
                    tint: denied ? VoleTheme.Colors.soil : VoleTheme.Colors.sage,
                    message: denied ? "可能未授权（扫描结果可能偏少）" : "探测通过"
                ) {
                    Button("打开系统设置") { FDAProbe.openSettings() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }

                Text(
                    "请勾选 \(FDAProbe.displayAppName)；若仍见灰色占位的 vole-macos.app，先删掉再用「+」添加访达中高亮的 \(FDAProbe.displayAppName).app。"
                )
                .font(VoleTheme.TypeScale.caption())
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct SettingsTouchIdSection: View {
    @ObservedObject var tools: SettingsToolsModel

    var body: some View {
        SettingsSectionCard(title: "Touch ID") {
            VStack(alignment: .leading, spacing: VoleTheme.Spacing.xs) {
                Text(tools.touchIdMessage.isEmpty ? "尚未检查" : tools.touchIdMessage)
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                SettingsActionRow {
                    Button(tools.touchIdBusy ? "…" : "刷新状态") { tools.refreshTouchId() }
                        .disabled(tools.touchIdBusy)
                    Button("启用") { tools.enableTouchId() }
                        .disabled(tools.touchIdBusy)
                    Button("禁用") { tools.disableTouchId() }
                        .disabled(tools.touchIdBusy)
                }
            }
        }
    }
}

private struct SettingsUpdateSection: View {
    @ObservedObject var tools: SettingsToolsModel
    let onConfirmInstall: () -> Void

    var body: some View {
        SettingsSectionCard(title: "更新") {
            VStack(alignment: .leading, spacing: VoleTheme.Spacing.xs) {
                Text(tools.updateMessage.isEmpty ? "可检查 sidecar 是否有新版本" : tools.updateMessage)
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                SettingsActionRow {
                    Button(tools.updateBusy ? "…" : "检查更新") { tools.checkForUpdate() }
                        .disabled(tools.updateBusy)
                    Button("安装更新", action: onConfirmInstall)
                        .disabled(tools.updateBusy)
                }
            }
        }
    }
}

private struct SettingsRemoveSection: View {
    @ObservedObject var tools: SettingsToolsModel
    let onConfirmRemove: () -> Void

    var body: some View {
        SettingsSectionCard(title: "自卸载") {
            VStack(alignment: .leading, spacing: VoleTheme.Spacing.xs) {
                Text(tools.removeMessage.isEmpty ? "预览后确认删除本工具安装产物" : tools.removeMessage)
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Toggle("同时删除审计日志", isOn: $tools.purgeOplog)
                    .font(VoleTheme.TypeScale.caption())
                    .toggleStyle(.checkbox)
                    .controlSize(.small)

                if !tools.removeItems.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(tools.removeItems.prefix(8)) { item in
                            Text("\(item.kind): \(item.path)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                }

                SettingsActionRow {
                    Button(tools.removeBusy ? "…" : "预览") { tools.previewRemove() }
                        .disabled(tools.removeBusy)
                    Button("确认自卸载", role: .destructive, action: onConfirmRemove)
                        .disabled(tools.removeBusy || tools.removeItems.isEmpty)
                }
            }
        }
    }
}

private struct SettingsAboutSection: View {
    let voleVersion: String
    let onRefreshVersion: () -> Void

    var body: some View {
        SettingsSectionCard(title: "关于") {
            HStack(alignment: .center, spacing: VoleTheme.Spacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("田鼠工坊 · Vole")
                        .font(VoleTheme.TypeScale.body())
                        .foregroundStyle(VoleTheme.Colors.text)
                    if voleVersion.isEmpty {
                        Text("sidecar 版本未知（可点刷新）")
                            .font(VoleTheme.TypeScale.caption())
                            .foregroundStyle(.secondary)
                    } else {
                        Text(voleVersion)
                            .font(VoleTheme.TypeScale.metric())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
                Spacer(minLength: VoleTheme.Spacing.sm)
                Button("刷新版本", action: onRefreshVersion)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
    }
}
