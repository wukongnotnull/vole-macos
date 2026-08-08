import SwiftUI

func selectedTotalBytes(entries: [VolePlanEntry], selectedIDs: Set<String>) -> UInt64 {
    entries.reduce(0) { $0 + (selectedIDs.contains($1.id) ? $1.size : 0) }
}

func strataFraction(entries: [VolePlanEntry], selectedIDs: Set<String>) -> Double {
    let total = entries.reduce(UInt64(0)) { $0 + $1.size }
    guard total > 0 else { return 0 }
    return Double(selectedTotalBytes(entries: entries, selectedIDs: selectedIDs)) / Double(total)
}

struct CleanCandidatesView: View {
    @ObservedObject var session: CleanSession
    @ObservedObject var helperStatus: HelperStatusModel
    @State private var confirm = false

    private var selectedPrivilegedCount: Int {
        session.entries
            .filter { session.selectedIDs.contains($0.id) && PathAuthorization.requiresPrivilegedHelper($0.path) }
            .count
    }

    private var selectedBytes: UInt64 {
        selectedTotalBytes(entries: session.entries, selectedIDs: session.selectedIDs)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: VoleTheme.Spacing.xs) {
                    Text("Candidates · 候选")
                        .font(VoleTheme.TypeScale.eyebrow())
                        .tracking(1.5)
                        .foregroundStyle(.secondary)
                    Text("挑要清掉的")
                        .font(VoleTheme.TypeScale.title())
                }
                Spacer()
                Button("全选") { session.selectedIDs = Set(session.entries.map(\.id)) }
                Button("全不选") { session.selectedIDs = [] }
            }

            SoilPanel(
                fraction: strataFraction(entries: session.entries, selectedIDs: session.selectedIDs),
                valueText: ByteFormat.string(selectedBytes),
                caption: "已选 \(session.selectedIDs.count) · 共 \(session.entries.count)"
            )

            if let note = session.coverageNote {
                Text(note)
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.secondary)
            }

            if selectedPrivilegedCount > 0 && !helperStatus.isReady {
                Text("已选 \(selectedPrivilegedCount) 项系统路径：特权助手未就绪，清理时将跳过这些项（不会假装成功）。")
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.orange)
            } else if selectedPrivilegedCount > 0 {
                Text("已选 \(selectedPrivilegedCount) 项系统路径将经特权助手永久删除（非废纸篓）。")
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.secondary)
            }

            if let error = session.errorMessage {
                Text(error)
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.orange)
            }

            List {
                ForEach(session.entries) { entry in
                    candidateRow(entry)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)

            HStack(spacing: VoleTheme.Spacing.md) {
                Button("重新扫描") { session.startScan() }
                Button("清理到废纸篓") { confirm = true }
                    .buttonStyle(.borderedProminent)
                    .tint(VoleTheme.Colors.soil)
                    .keyboardShortcut(.defaultAction)
                    .disabled(session.selectedIDs.isEmpty)
                Spacer()
                Text("Enter · 默认动作")
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(VoleTheme.Spacing.xl)
        .background(VoleTheme.Colors.contentBackground)
        .confirmationDialog(
            selectedPrivilegedCount > 0
                ? "用户域移到废纸篓；系统路径经特权助手永久删除（助手未就绪则跳过）"
                : "将把已选项目移到废纸篓",
            isPresented: $confirm,
            titleVisibility: .visible
        ) {
            Button("确认清理", role: .destructive) { session.applySelected() }
            Button("取消", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func candidateRow(_ entry: VolePlanEntry) -> some View {
        let isPrivileged = PathAuthorization.requiresPrivilegedHelper(entry.path)
        Toggle(isOn: Binding(
            get: { session.selectedIDs.contains(entry.id) },
            set: { on in
                var ids = session.selectedIDs
                if on { ids.insert(entry.id) } else { ids.remove(entry.id) }
                session.selectedIDs = ids
            }
        )) {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(entry.label)
                        .font(VoleTheme.TypeScale.body().weight(.semibold))
                    if isPrivileged {
                        Text("需助手")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(VoleTheme.Colors.soil)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(VoleTheme.Colors.molehill.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    Spacer()
                    Text(ByteFormat.string(entry.size))
                        .font(VoleTheme.TypeScale.metric())
                        .foregroundStyle(.secondary)
                }
                Text(entry.path)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .toggleStyle(.checkbox)
        .accessibilityLabel("\(entry.label)，\(ByteFormat.string(entry.size))")
        .accessibilityValue(session.selectedIDs.contains(entry.id) ? "已选" : "未选")
        .accessibilityHint(isPrivileged ? "系统路径，需特权助手永久删除" : "移动到废纸篓")
    }
}
