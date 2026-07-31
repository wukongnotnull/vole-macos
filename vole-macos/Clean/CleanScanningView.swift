import SwiftUI

struct CleanScanningView: View {
    @ObservedObject var session: CleanSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("扫描中…").font(.title2.bold())
            ProgressView()
            Text("已扫描 \(session.progressScanned) 项")
            Text(session.progressCurrent).lineLimit(2).foregroundStyle(.secondary)
            Button("取消", role: .cancel) { session.cancel() }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
