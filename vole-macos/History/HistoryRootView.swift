import SwiftUI

struct HistoryRootView: View {
    @ObservedObject var session: HistorySession

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: VoleTheme.Spacing.xs) {
                    Text("History · 历史")
                        .font(VoleTheme.TypeScale.eyebrow())
                        .tracking(1.5)
                        .foregroundStyle(.secondary)
                    Text("操作历史")
                        .font(VoleTheme.TypeScale.title())
                }
                Spacer()
                Stepper(
                    value: $session.limit,
                    in: HistorySession.minLimit...HistorySession.maxLimit,
                    step: 5
                ) {
                    Text("条数 \(session.limit)")
                        .font(VoleTheme.TypeScale.caption())
                }
                .frame(maxWidth: 160)
                Button(session.isRefreshing ? "刷新中…" : "刷新") {
                    session.refresh()
                }
                .disabled(session.isRefreshing)
            }

            if let error = session.errorMessage {
                Text(error)
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.orange)
            }

            if let snap = session.snapshot {
                if snap.sessions.isEmpty && snap.deletions.isEmpty {
                    Text("暂无操作记录")
                        .font(VoleTheme.TypeScale.body())
                        .foregroundStyle(.secondary)
                } else {
                    List {
                        if !snap.sessions.isEmpty {
                            Section("会话") {
                                ForEach(snap.sessions) { item in
                                    sessionRow(item)
                                }
                            }
                        }
                        if !snap.deletions.isEmpty {
                            Section("删除审计") {
                                ForEach(snap.deletions) { item in
                                    deletionRow(item)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                }
            } else if session.errorMessage == nil {
                Text(session.isRefreshing ? "正在加载…" : "点「刷新」查看操作历史。")
                    .font(VoleTheme.TypeScale.body())
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(VoleTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(VoleTheme.Colors.contentBackground)
        .onAppear {
            if session.snapshot == nil {
                session.refresh()
            }
        }
    }

    @ViewBuilder
    private func sessionRow(_ item: HistorySessionItem) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(item.command)
                    .font(VoleTheme.TypeScale.body().weight(.semibold))
                Spacer()
                Text(item.size)
                    .font(VoleTheme.TypeScale.metric())
                    .foregroundStyle(.secondary)
            }
            Text("\(item.startedAt) → \(item.endedAt.isEmpty ? "…" : item.endedAt)")
                .font(VoleTheme.TypeScale.caption())
                .foregroundStyle(.secondary)
            Text("\(item.items) 项 · \(item.actionsSummary)")
                .font(VoleTheme.TypeScale.caption())
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func deletionRow(_ item: HistoryDeletionItem) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("\(item.mode) · \(item.status)")
                    .font(VoleTheme.TypeScale.body().weight(.semibold))
                Spacer()
                if let kb = item.sizeKb {
                    Text("\(kb) KB")
                        .font(VoleTheme.TypeScale.metric())
                        .foregroundStyle(.secondary)
                }
            }
            Text(item.timestamp)
                .font(VoleTheme.TypeScale.caption())
                .foregroundStyle(.secondary)
            Text(item.path)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.tertiary)
                .lineLimit(2)
                .truncationMode(.middle)
                .textSelection(.enabled)
        }
        .padding(.vertical, 2)
    }
}
