import SwiftUI

struct CleanResultView: View {
    @ObservedObject var session: CleanSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("完成").font(.title2.bold())
            if let report = session.report {
                Text("成功 \(report.succeeded) · 跳过 \(report.skipped) · 失败 \(report.failed)")
                Text("移入废纸篓 \(ByteFormat.string(report.trashedBytes))")
            }
            if let error = session.errorMessage {
                Text(error).foregroundStyle(.orange)
            }
            Button("完成") { session.reset() }
                .keyboardShortcut(.defaultAction)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
