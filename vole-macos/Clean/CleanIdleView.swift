import SwiftUI

struct CleanIdleView: View {
    @ObservedObject var session: CleanSession
    @ObservedObject var helperStatus: HelperStatusModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("清理").font(.largeTitle.bold())
            Text("扫描可清理的缓存与残留，确认后移到废纸篓。系统路径需特权助手。")
                .foregroundStyle(.secondary)
            HelperStatusCard(model: helperStatus)
            if !session.voleVersion.isEmpty {
                Text("sidecar: \(session.voleVersion)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let error = session.errorMessage {
                Text(error).foregroundStyle(.red)
            }
            Button("扫描") { session.startScan() }
                .keyboardShortcut(.defaultAction)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
