import SwiftUI

struct CleanApplyingView: View {
    @ObservedObject var session: CleanSession
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: VoleTheme.Spacing.xs) {
                Text("Applying · 清理中")
                    .font(VoleTheme.TypeScale.eyebrow())
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
                Text("正在清理")
                    .font(VoleTheme.TypeScale.title())
            }

            SoilPanel(fraction: nil, valueText: "…", caption: "移动中")
                .opacity(breathingOpacity)
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                    value: breathingOpacity
                )

            Text("用户域移到废纸篓；系统路径经特权助手永久删除。")
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
        .onAppear { breathingOpacity = 0.55 }
        .onDisappear { breathingOpacity = 1 }
    }

    @State private var breathingOpacity: Double = 1
}
