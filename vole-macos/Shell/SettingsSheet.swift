import SwiftUI

struct SettingsSheet: View {
    @ObservedObject var helperStatus: HelperStatusModel
    let voleVersion: String
    let onRefreshVersion: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
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
                Text("特权助手")
                    .font(VoleTheme.TypeScale.body().weight(.semibold))
                HelperStatusCard(model: helperStatus)
            }

            Group {
                Text("完全磁盘访问")
                    .font(VoleTheme.TypeScale.body().weight(.semibold))
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
                .padding(.horizontal, VoleTheme.Spacing.md)
                .padding(.vertical, VoleTheme.Spacing.sm)
                .background(VoleTheme.Colors.molehill.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: VoleTheme.Radius.control))
            }

            Group {
                Text("关于")
                    .font(VoleTheme.TypeScale.body().weight(.semibold))
                VStack(alignment: .leading, spacing: VoleTheme.Spacing.xs) {
                    Text("田鼠工坊 · vole-macos")
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

            Spacer(minLength: 0)
        }
        .padding(VoleTheme.Spacing.xl)
        .frame(minWidth: 420, minHeight: 360)
        .background(VoleTheme.Colors.contentBackground)
        .onAppear {
            helperStatus.refresh()
            onRefreshVersion()
        }
    }

    private var fdaDenied: Bool { FDAProbe.looksDenied() }
}
