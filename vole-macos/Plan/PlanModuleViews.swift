import SwiftUI

struct PlanModuleIdleView: View {
    @ObservedObject var session: PlanModuleSession
    @ObservedObject var helperStatus: HelperStatusModel

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.xl) {
            Text(session.kind.idleHeadline)
                .font(VoleTheme.TypeScale.title())
                .foregroundStyle(VoleTheme.Colors.text)

            SoilPanel(fraction: nil, valueText: "—", caption: session.kind.idleCaption)

            HelperStatusCard(model: helperStatus)

            if let error = session.errorMessage {
                Text(error)
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.orange)
            }

            Spacer(minLength: 0)

            HStack(alignment: .center, spacing: VoleTheme.Spacing.md) {
                Button("开始扫描") { session.startScan() }
                    .buttonStyle(.borderedProminent)
                    .tint(VoleTheme.Colors.soil)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)

                Spacer()

                if !session.voleVersion.isEmpty {
                    Text(session.voleVersion)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .help("sidecar \(session.voleVersion)")
                }
            }
        }
        .padding(VoleTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(VoleTheme.Colors.contentBackground)
    }
}

struct PlanModuleScanningView: View {
    @ObservedObject var session: PlanModuleSession
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathingOpacity: Double = 1

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.lg) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: VoleTheme.Spacing.xs) {
                    Text(session.kind.scanEyebrow)
                        .font(VoleTheme.TypeScale.eyebrow())
                        .tracking(1.5)
                        .foregroundStyle(.secondary)
                    Text(session.kind.scanTitle)
                        .font(VoleTheme.TypeScale.title())
                }
                Spacer()
                Image("VoleLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .accessibilityLabel("Vole 田鼠")
            }

            SoilPanel(fraction: nil, valueText: "\(session.progressScanned)", caption: "已扫条目")
                .opacity(breathingOpacity)
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                    value: breathingOpacity
                )

            Text(session.progressCurrent)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .truncationMode(.middle)

            if let error = session.errorMessage {
                Text(error)
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.orange)
            }

            Spacer()

            HStack {
                Button("取消", role: .cancel) { session.cancel() }
                Spacer()
                Text("可取消 · 不会动文件")
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(VoleTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(VoleTheme.Colors.contentBackground)
        .onAppear { breathingOpacity = 0.55 }
        .onDisappear { breathingOpacity = 1 }
    }
}

struct PlanModuleCandidatesView: View {
    @ObservedObject var session: PlanModuleSession
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

    private var candidatesCaption: String {
        let selected = session.selectedIDs.count
        let total = session.entries.count
        if selected == total {
            return "\(total) 项"
        }
        return "\(selected) / \(total)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: VoleTheme.Spacing.xs) {
                    Text(session.kind.candidatesEyebrow)
                        .font(VoleTheme.TypeScale.eyebrow())
                        .tracking(1.5)
                        .foregroundStyle(.secondary)
                    Text(session.kind.candidatesTitle)
                        .font(VoleTheme.TypeScale.title())
                }
                Spacer()
                Button("全选") { session.selectedIDs = Set(session.entries.map(\.id)) }
                Button("全不选") { session.selectedIDs = [] }
            }

            SoilPanel(
                fraction: strataFraction(entries: session.entries, selectedIDs: session.selectedIDs),
                valueText: ByteFormat.string(selectedBytes),
                caption: candidatesCaption
            )

            if session.entries.isEmpty {
                Text("扫描完成，当前无候选（真实空态）。")
                    .font(VoleTheme.TypeScale.body())
                    .foregroundStyle(.secondary)
            }

            if selectedPrivilegedCount > 0 && !helperStatus.isReady {
                Text("已选 \(selectedPrivilegedCount) 项系统路径：特权助手未就绪，执行时将跳过这些项（不会假装成功）。")
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.orange)
            } else if selectedPrivilegedCount > 0 {
                Text("已选 \(selectedPrivilegedCount) 项系统路径将经特权助手永久删除（非废纸篓）。")
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.secondary)
            }

            if let note = session.coverageNote, !note.isEmpty {
                Text(note)
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
                Button(session.kind.primaryActionTitle) { confirm = true }
                    .buttonStyle(.borderedProminent)
                    .tint(VoleTheme.Colors.soil)
                    .keyboardShortcut(.defaultAction)
                    .disabled(session.selectedIDs.isEmpty)
                Spacer()
            }
        }
        .padding(VoleTheme.Spacing.xl)
        .background(VoleTheme.Colors.contentBackground)
        .confirmationDialog(
            session.kind.confirmTitle,
            isPresented: $confirm,
            titleVisibility: .visible
        ) {
            Button(session.kind.confirmButton, role: .destructive) { session.applySelected() }
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
                Text(entry.ruleID)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.quaternary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .toggleStyle(.checkbox)
    }
}

struct PlanModuleApplyingView: View {
    @ObservedObject var session: PlanModuleSession
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathingOpacity: Double = 1

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: VoleTheme.Spacing.xs) {
                Text(session.kind.applyEyebrow)
                    .font(VoleTheme.TypeScale.eyebrow())
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
                Text(session.kind.applyTitle)
                    .font(VoleTheme.TypeScale.title())
            }

            SoilPanel(fraction: nil, valueText: "…", caption: "执行中")
                .opacity(breathingOpacity)
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                    value: breathingOpacity
                )

            Text(session.kind.applyHint)
                .font(VoleTheme.TypeScale.body())
                .foregroundStyle(.secondary)

            if !session.progressCurrent.isEmpty {
                Text(session.progressCurrent)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            if let error = session.errorMessage {
                Text(error)
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.orange)
            }

            Spacer()

            HStack {
                Button("取消", role: .cancel) { session.cancel() }
                Spacer()
                Text("取消可能已部分执行")
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(VoleTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(VoleTheme.Colors.contentBackground)
        .onAppear { breathingOpacity = 0.55 }
        .onDisappear { breathingOpacity = 1 }
    }
}

struct PlanModuleResultView: View {
    @ObservedObject var session: PlanModuleSession

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.lg) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: VoleTheme.Spacing.xs) {
                    Text("Result · 完成")
                        .font(VoleTheme.TypeScale.eyebrow())
                        .tracking(1.5)
                        .foregroundStyle(.secondary)
                    Text(session.kind.resultTitle)
                        .font(VoleTheme.TypeScale.title())
                }
                Spacer()
                Image("VoleLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .accessibilityLabel("Vole 田鼠")
            }

            if let report = session.report {
                SoilPanel(
                    fraction: 1,
                    valueText: ByteFormat.string(recoveredBytes(report)),
                    caption: "已回收 / 触及"
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
