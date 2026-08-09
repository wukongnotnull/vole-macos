import SwiftUI

struct StatusRootView: View {
    @ObservedObject var session: StatusSession

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.lg) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: VoleTheme.Spacing.xs) {
                    Text("Status · 状态")
                        .font(VoleTheme.TypeScale.eyebrow())
                        .tracking(1.5)
                        .foregroundStyle(.secondary)
                    Text("地道仪表")
                        .font(VoleTheme.TypeScale.title())
                }
                Spacer()
                Toggle("实时", isOn: Binding(
                    get: { session.isLive },
                    set: { on in
                        if on { session.startLive() } else { session.stopLive() }
                    }
                ))
                .toggleStyle(.switch)
                .controlSize(.small)
                Button(session.isRefreshing ? "刷新中…" : "刷新") {
                    session.refreshOnce()
                }
                .disabled(session.isRefreshing)
            }

            if let error = session.errorMessage {
                Text(error)
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.orange)
            }

            if let snap = session.snapshot {
                dashboard(snap)
            } else if session.errorMessage == nil {
                Text(session.isRefreshing ? "正在采集…" : "尚未采集。点「刷新」或打开「实时」。")
                    .font(VoleTheme.TypeScale.body())
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            if !session.voleVersion.isEmpty {
                Text(session.voleVersion)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(VoleTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(VoleTheme.Colors.contentBackground)
        .onAppear {
            session.refreshVersion()
            if session.snapshot == nil {
                session.refreshOnce()
            }
        }
        .onDisappear {
            session.stopLive()
        }
    }

    @ViewBuilder
    private func dashboard(_ snap: StatusSnapshot) -> some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.md) {
            SoilPanel(
                valueText: "\(snap.healthScore)",
                caption: snap.healthScoreMsg.isEmpty ? "健康分" : snap.healthScoreMsg
            )

            HStack(spacing: VoleTheme.Spacing.md) {
                metricCard(title: "CPU", value: String(format: "%.0f%%", snap.cpu.usage))
                metricCard(
                    title: "内存",
                    value: String(format: "%.0f%%", snap.memory.usedPercent)
                )
                metricCard(title: "进程", value: "\(snap.procs)")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(snap.host) · \(snap.platform)")
                    .font(VoleTheme.TypeScale.body().weight(.semibold))
                Text("开机 \(snap.uptime)")
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.secondary)
                Text("采集 \(snap.collectedAt)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }

            if !snap.disks.isEmpty {
                Text("磁盘")
                    .font(VoleTheme.TypeScale.body().weight(.semibold))
                ForEach(snap.disks.prefix(6)) { disk in
                    HStack {
                        Text(disk.mount)
                            .font(.system(.caption, design: .monospaced))
                        Spacer()
                        Text(String(format: "%.0f%% · %@", disk.usedPercent, ByteFormat.string(disk.used)))
                            .font(VoleTheme.TypeScale.caption())
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack {
                Text("废纸篓 \(ByteFormat.string(snap.trashSize))\(snap.trashApprox ? "（约）" : "")")
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.secondary)
                Spacer()
                if let local = snap.localSnapshots {
                    Text(local.message)
                        .font(VoleTheme.TypeScale.caption())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
        }
    }

    private func metricCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(VoleTheme.TypeScale.caption())
                .foregroundStyle(.secondary)
            Text(value)
                .font(VoleTheme.TypeScale.metric())
        }
        .padding(VoleTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(VoleTheme.Colors.molehill.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: VoleTheme.Radius.control))
    }
}
