import SwiftUI

struct CleanIdleView: View {
    @ObservedObject var session: CleanSession
    @ObservedObject var helperStatus: HelperStatusModel
    @State private var fdaDenied = false

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.xl) {
            CleanIdleHeader()

            SoilPanel(valueText: "—", caption: CleanIdlePresentation.soilCaption)

            Text(CleanIdlePresentation.supportingCopy)
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

            CleanIdleFooter(
                version: session.voleVersion,
                fdaDenied: fdaDenied,
                onScan: { session.startScan() },
                onOpenFDASettings: { FDAProbe.openSettings() }
            )
        }
        .padding(VoleTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(VoleTheme.Colors.contentBackground)
        .onAppear {
            helperStatus.refresh()
            fdaDenied = FDAProbe.looksDenied()
        }
    }
}

private struct CleanIdleHeader: View {
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: VoleTheme.Spacing.xs) {
                Text("Clean · 清理")
                    .voleEyebrowStyle()
                Text("翻土找缓存")
                    .voleTitleStyle()
                    .foregroundStyle(VoleTheme.Colors.text)
            }
            Spacer(minLength: VoleTheme.Spacing.sm)
            VoleMascotView(state: .idle, size: 44)
        }
    }
}

private struct CleanIdleFooter: View {
    let version: String
    let fdaDenied: Bool
    let onScan: () -> Void
    let onOpenFDASettings: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: VoleTheme.Spacing.md) {
            Button("开始扫描", action: onScan)
                .buttonStyle(.borderedProminent)
                .tint(VoleTheme.Colors.soil)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)

            Spacer(minLength: 0)

            Button(action: onOpenFDASettings) {
                Text(CleanIdlePresentation.fdaCaption(denied: fdaDenied))
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(fdaDenied ? VoleTheme.Colors.fur : VoleTheme.Colors.text.opacity(0.35))
            }
            .buttonStyle(.plain)
            .help(fdaDenied ? "打开系统设置授予完全磁盘访问" : "完全磁盘访问已授权")

            if !version.isEmpty {
                Text(version)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .help("sidecar \(version)")
            }
        }
    }
}
