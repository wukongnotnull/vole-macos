import SwiftUI

func recoveredBytes(_ report: VoleReport) -> UInt64 {
    report.trashedBytes + report.deletedBytes
}

struct CleanResultView: View {
    @ObservedObject var session: CleanSession

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.lg) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: VoleTheme.Spacing.xs) {
                    Text("Result · 完成")
                        .font(VoleTheme.TypeScale.eyebrow())
                        .tracking(1.5)
                        .foregroundStyle(.secondary)
                    Text("翻土完成")
                        .font(VoleTheme.TypeScale.title())
                }
                Spacer()
                VoleMascotView(state: .success, size: 44)
            }

            if let report = session.report {
                SoilPanel(
                    valueText: ByteFormat.string(recoveredBytes(report)),
                    caption: "已回收"
                )

                HStack(spacing: VoleTheme.Spacing.md) {
                    Label("成功 \(report.succeeded)", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Label("跳过 \(report.skipped)", systemImage: "arrow.uturn.right.circle")
                        .foregroundStyle(.secondary)
                    Label("失败 \(report.failed)", systemImage: "xmark.circle")
                        .foregroundStyle(.orange)
                }
                .font(VoleTheme.TypeScale.caption())

                if let note = session.helperDegradeNote {
                    Text(note)
                        .font(VoleTheme.TypeScale.caption())
                        .foregroundStyle(.orange)
                }
            }

            if let error = session.errorMessage {
                Text(error)
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.orange)
            }

            Spacer()

            HStack {
                Button("完成") { session.reset() }
                    .buttonStyle(.borderedProminent)
                    .tint(VoleTheme.Colors.soil)
                    .keyboardShortcut(.defaultAction)
                Spacer()
                Text("返回空闲")
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(VoleTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(VoleTheme.Colors.contentBackground)
    }
}
