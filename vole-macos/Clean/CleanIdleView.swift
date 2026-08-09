import SwiftUI

struct CleanIdleView: View {
    @ObservedObject var session: CleanSession

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.xl) {
            VStack(alignment: .leading, spacing: VoleTheme.Spacing.xs) {
                Text("Clean · 清理")
                    .voleEyebrowStyle()
                Text("翻土找缓存")
                    .voleTitleStyle()
                    .foregroundStyle(VoleTheme.Colors.text)
            }

            SoilPanel(valueText: "—", caption: "待扫描")

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

                Spacer()

                if !session.voleVersion.isEmpty {
                    Text(session.voleVersion)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .help("sidecar \(session.voleVersion)")
                }
            }
        }
        .padding(VoleTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(VoleTheme.Colors.contentBackground)
    }
}
