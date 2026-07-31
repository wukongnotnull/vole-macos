import SwiftUI

struct CleanCandidatesView: View {
    @ObservedObject var session: CleanSession
    @State private var confirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("候选").font(.title2.bold())
                Spacer()
                Button("全选") { session.selectedIDs = Set(session.entries.map(\.id)) }
                Button("全不选") { session.selectedIDs = [] }
            }
            if let note = session.coverageNote {
                Text(note).font(.caption).foregroundStyle(.secondary)
            }
            if let error = session.errorMessage {
                Text(error).foregroundStyle(.red)
            }
            List {
                ForEach(session.entries) { entry in
                    Toggle(isOn: Binding(
                        get: { session.selectedIDs.contains(entry.id) },
                        set: { on in
                            var ids = session.selectedIDs
                            if on { ids.insert(entry.id) } else { ids.remove(entry.id) }
                            session.selectedIDs = ids
                        }
                    )) {
                        VStack(alignment: .leading) {
                            Text(entry.label)
                            Text("\(ByteFormat.string(entry.size)) · \(entry.ruleID)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(entry.path)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            HStack {
                Text("已选 \(session.selectedIDs.count) · 共 \(session.entries.count)")
                Spacer()
                Button("重新扫描") { session.startScan() }
                Button("清理到废纸篓") { confirm = true }
                    .keyboardShortcut(.defaultAction)
                    .disabled(session.selectedIDs.isEmpty)
            }
        }
        .confirmationDialog("将把已选项目移到废纸篓", isPresented: $confirm, titleVisibility: .visible) {
            Button("确认清理", role: .destructive) { session.applySelected() }
            Button("取消", role: .cancel) {}
        }
    }
}
