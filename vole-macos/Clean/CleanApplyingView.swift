import SwiftUI

struct CleanApplyingView: View {
    @ObservedObject var session: CleanSession

    private var applyTotal: Int { session.selectedIDs.count }

    private var usesIndeterminate: Bool {
        applyUsesIndeterminateProgress(
            scanned: session.progressScanned,
            total: applyTotal,
            progressCurrent: session.progressCurrent
        )
    }

    private var valueText: String {
        if usesIndeterminate {
            return "…"
        }
        return applyProgressValueText(scanned: session.progressScanned, total: applyTotal)
    }

    private var caption: String {
        usesIndeterminate ? "移动中" : "已处理"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.lg) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: VoleTheme.Spacing.xs) {
                    Text("Applying · 清理中")
                        .font(VoleTheme.TypeScale.eyebrow())
                        .tracking(1.5)
                        .foregroundStyle(.secondary)
                    Text("正在清理")
                        .font(VoleTheme.TypeScale.title())
                }
                Spacer()
                VoleMascotView(state: .applying, size: 44)
            }

            SoilPanel(
                valueText: valueText,
                caption: caption
            )

            Text("个人文件移到废纸篓；需管理员权限的文件经 root权限助手永久删除。")
                .font(VoleTheme.TypeScale.body())
                .foregroundStyle(.secondary)

            if !session.progressCurrent.isEmpty {
                Text(session.progressCurrent)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            if let error = session.errorMessage {
                Text(error)
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.orange)
            }

            Spacer()

            HStack {
                Button("取消", role: .cancel) { session.cancel() }
                Spacer()
                Text("取消可能已部分清理")
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(VoleTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(VoleTheme.Colors.contentBackground)
    }
}
