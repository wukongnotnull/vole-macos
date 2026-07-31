import SwiftUI

struct CleanApplyingView: View {
    @ObservedObject var session: CleanSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("清理中…").font(.title2.bold())
            ProgressView()
            Text(session.progressCurrent).foregroundStyle(.secondary)
            Text("取消后可能已有部分项目进入废纸篓。").font(.caption).foregroundStyle(.secondary)
            Button("取消", role: .cancel) { session.cancel() }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
