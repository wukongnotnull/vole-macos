import SwiftUI

struct CleanScanningView: View {
    @ObservedObject var session: CleanSession
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.lg) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: VoleTheme.Spacing.xs) {
                    Text("Scanning · 扫描中")
                        .font(VoleTheme.TypeScale.eyebrow())
                        .tracking(1.5)
                        .foregroundStyle(.secondary)
                    Text("正在翻找")
                        .font(VoleTheme.TypeScale.title())
                }
                Spacer()
                Image("VoleLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .accessibilityLabel("Vole 田鼠")
            }

            SoilPanel(fraction: nil, valueText: "\(session.progressScanned)", caption: "已扫条目")
                .opacity(breathingOpacity)
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                    value: breathingOpacity
                )

            Text(session.progressCurrent)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .truncationMode(.middle)

            if let error = session.errorMessage {
                Text(error)
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.orange)
            }

            Spacer()

            HStack {
                Button("取消", role: .cancel) { session.cancel() }
                Spacer()
                Text("可取消 · 不会动文件")
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
