import SwiftUI

struct CleanIdleView: View {
    @ObservedObject var session: CleanSession
    @ObservedObject var helperStatus: HelperStatusModel

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: VoleTheme.Spacing.xs) {
                Text("Clean · 清理")
                    .font(VoleTheme.TypeScale.eyebrow())
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
                Text("翻土找缓存")
                    .font(VoleTheme.TypeScale.title())
                    .foregroundStyle(VoleTheme.Colors.text)
            }

            SoilPanel(fraction: nil, valueText: "—", caption: "可回收层 · 待扫描")

            Text("扫描缓存与残留，确认后移到废纸篓。系统路径需特权助手。")
                .font(VoleTheme.TypeScale.body())
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HelperStatusCard(model: helperStatus)

            if let error = session.errorMessage {
                Text(error)
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.orange)
            }

            Spacer(minLength: 0)

            HStack(alignment: .center, spacing: VoleTheme.Spacing.md) {
                Button("开始扫描") { session.startScan() }
                    .buttonStyle(.borderedProminent)
                    .tint(VoleTheme.Colors.soil)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
                if !helperStatus.isReady {
                    Text("系统路径暂不可用")
                        .font(VoleTheme.TypeScale.caption())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if !session.voleVersion.isEmpty {
                    Text("sidecar \(session.voleVersion)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(VoleTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(VoleTheme.Colors.contentBackground)
    }
}
