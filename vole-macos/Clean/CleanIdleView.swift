import SwiftUI

struct CleanIdleView: View {
    @ObservedObject var session: CleanSession
    @ObservedObject var helperStatus: HelperStatusModel

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.xl) {
            Text("翻土找缓存")
                .font(VoleTheme.TypeScale.title())
                .foregroundStyle(VoleTheme.Colors.text)

            SoilPanel(fraction: nil, valueText: "—", caption: "待扫描")

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
