import SwiftUI

struct SettingsSheet: View {
    @ObservedObject var helperStatus: HelperStatusModel
    @ObservedObject var tools: SettingsToolsModel
    let voleVersion: String
    let onRefreshVersion: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var confirmUpdate = false
    @State private var confirmRemove = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VoleTheme.Spacing.lg) {
                HStack {
                    VStack(alignment: .leading, spacing: VoleTheme.Spacing.xs) {
                        Text("Settings · 设置")
                            .font(VoleTheme.TypeScale.eyebrow())
                            .tracking(1.5)
                            .foregroundStyle(.secondary)
                        Text("工坊设置")
                            .font(VoleTheme.TypeScale.title())
                    }
                    Spacer()
                    Button("完成") { dismiss() }
                        .keyboardShortcut(.defaultAction)
                }

                Group {
                    Text("root权限助手")
                        .font(VoleTheme.TypeScale.body().weight(.semibold))
                    HelperStatusCard(model: helperStatus)
                }

                Group {
                    Text("完全磁盘访问")
                        .font(VoleTheme.TypeScale.body().weight(.semibold))
                    VStack(alignment: .leading, spacing: VoleTheme.Spacing.sm) {
                        HStack(spacing: VoleTheme.Spacing.sm) {
                            Image(systemName: fdaDenied ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                                .foregroundStyle(fdaDenied ? VoleTheme.Colors.soil : VoleTheme.Colors.sage)
                            Text(fdaDenied ? "可能未授权（扫描结果可能偏少）" : "探测通过")
                                .font(VoleTheme.TypeScale.body())
                            Spacer()
                            Button("打开系统设置") { FDAProbe.openSettings() }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                        }
                        Text("请勾选 \(FDAProbe.displayAppName)；若仍见灰色占位的 vole-macos.app，先删掉再用「+」添加访达中高亮的 \(FDAProbe.displayAppName).app。")
                            .font(VoleTheme.TypeScale.caption())
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, VoleTheme.Spacing.md)
                    .padding(.vertical, VoleTheme.Spacing.sm)
                    .background(VoleTheme.Colors.molehill.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: VoleTheme.Radius.control))
                }

                touchIdSection
                updateSection
                removeSection

                Group {
                    Text("关于")
                        .font(VoleTheme.TypeScale.body().weight(.semibold))
                    VStack(alignment: .leading, spacing: VoleTheme.Spacing.xs) {
                        Text("田鼠工坊 · Vole")
                            .font(VoleTheme.TypeScale.body())
                        if voleVersion.isEmpty {
                            Text("sidecar 版本未知（可点刷新）")
                                .font(VoleTheme.TypeScale.caption())
                                .foregroundStyle(.secondary)
                        } else {
                            Text(voleVersion)
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                        Button("刷新版本") { onRefreshVersion() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                }
            }
            .padding(VoleTheme.Spacing.xl)
        }
        .frame(minWidth: 460, minHeight: 520)
        .background(VoleTheme.Colors.contentBackground)
        .onAppear {
            helperStatus.refresh()
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

    private var fdaDenied: Bool { FDAProbe.looksDenied() }

    private var touchIdSection: some View {
        Group {
            Text("Touch ID")
                .font(VoleTheme.TypeScale.body().weight(.semibold))
            VStack(alignment: .leading, spacing: VoleTheme.Spacing.sm) {
                Text(tools.touchIdMessage.isEmpty ? "尚未检查" : tools.touchIdMessage)
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.secondary)
                HStack(spacing: VoleTheme.Spacing.sm) {
                    Button(tools.touchIdBusy ? "…" : "刷新状态") { tools.refreshTouchId() }
                        .disabled(tools.touchIdBusy)
                    Button("启用") { tools.enableTouchId() }
                        .disabled(tools.touchIdBusy)
                    Button("禁用") { tools.disableTouchId() }
                        .disabled(tools.touchIdBusy)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    private var updateSection: some View {
        Group {
            Text("更新")
                .font(VoleTheme.TypeScale.body().weight(.semibold))
            VStack(alignment: .leading, spacing: VoleTheme.Spacing.sm) {
                Text(tools.updateMessage.isEmpty ? "可检查 sidecar 是否有新版本" : tools.updateMessage)
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.secondary)
                HStack(spacing: VoleTheme.Spacing.sm) {
                    Button(tools.updateBusy ? "…" : "检查更新") { tools.checkForUpdate() }
                        .disabled(tools.updateBusy)
                    Button("安装更新") { confirmUpdate = true }
                        .disabled(tools.updateBusy)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    private var removeSection: some View {
        Group {
            Text("自卸载")
                .font(VoleTheme.TypeScale.body().weight(.semibold))
            VStack(alignment: .leading, spacing: VoleTheme.Spacing.sm) {
                Text(tools.removeMessage.isEmpty ? "预览后确认删除本工具安装产物" : tools.removeMessage)
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.secondary)
                Toggle("同时删除审计日志", isOn: $tools.purgeOplog)
                    .font(VoleTheme.TypeScale.caption())
                if !tools.removeItems.isEmpty {
                    ForEach(tools.removeItems.prefix(8)) { item in
                        Text("\(item.kind): \(item.path)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                HStack(spacing: VoleTheme.Spacing.sm) {
                    Button(tools.removeBusy ? "…" : "预览") { tools.previewRemove() }
                        .disabled(tools.removeBusy)
                    Button("确认自卸载") { confirmRemove = true }
                        .disabled(tools.removeBusy || tools.removeItems.isEmpty)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
}
