import SwiftUI

func selectedTotalBytes(entries: [VolePlanEntry], selectedIDs: Set<String>) -> UInt64 {
    entries.reduce(0) { $0 + (selectedIDs.contains($1.id) ? $1.size : 0) }
}

func strataFraction(entries: [VolePlanEntry], selectedIDs: Set<String>) -> Double {
    let total = entries.reduce(UInt64(0)) { $0 + $1.size }
    guard total > 0 else { return 0 }
    return Double(selectedTotalBytes(entries: entries, selectedIDs: selectedIDs)) / Double(total)
}

private enum CandidateSizeFilter: UInt64, CaseIterable, Identifiable {
    case any = 0
    case tenMB = 10_485_760
    case hundredMB = 104_857_600
    case oneGB = 1_073_741_824

    var id: UInt64 { rawValue }

    var title: String {
        switch self {
        case .any: return "任意大小"
        case .tenMB: return "≥10MB"
        case .hundredMB: return "≥100MB"
        case .oneGB: return "≥1GB"
        }
    }
}

struct CleanCandidatesView: View {
    @ObservedObject var session: CleanSession
    @ObservedObject var helperStatus: HelperStatusModel
    @State private var confirm = false
    @State private var searchText = ""
    @State private var sizeFilter: CandidateSizeFilter = .any
    @State private var rootOnly = false
    @State private var page = 1
    @State private var pageSize = 50
    @State private var expandedCategories: Set<String> = []

    private var selectedPrivilegedCount: Int {
        session.entries
            .filter { session.selectedIDs.contains($0.id) && PathAuthorization.requiresPrivilegedHelper($0.path) }
            .count
    }

    private var selectedBytes: UInt64 {
        selectedTotalBytes(entries: session.entries, selectedIDs: session.selectedIDs)
    }

    private var query: CandidateListQuery {
        CandidateListQuery(
            searchText: searchText,
            minBytes: sizeFilter.rawValue,
            rootOnly: rootOnly
        )
    }

    private var presented: CandidateListPresented {
        CandidateListPresentation.present(
            entries: session.entries,
            query: query,
            page: page,
            pageSize: pageSize
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.md) {
            CleanCandidatesHeader(
                selectedCount: session.selectedIDs.count,
                totalCount: session.entries.count,
                selectedBytes: selectedBytes,
                onSelectAll: { session.selectedIDs = Set(session.entries.map(\.id)) },
                onSelectNone: { session.selectedIDs = [] }
            )

            CleanCandidatesFilterBar(
                searchText: $searchText,
                sizeFilter: $sizeFilter,
                rootOnly: $rootOnly
            )
            .onChange(of: searchText) { _, _ in page = 1 }
            .onChange(of: sizeFilter) { _, _ in page = 1 }
            .onChange(of: rootOnly) { _, _ in page = 1 }

            if selectedPrivilegedCount > 0 && !helperStatus.isReady {
                Text("已选含 \(selectedPrivilegedCount) 项系统级文件，需开启 Root 权限才能永久删除，否则将跳过。")
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.orange)
            } else if selectedPrivilegedCount > 0 {
                Text("已选含 \(selectedPrivilegedCount) 项系统级文件，将经 Root 权限永久删除（不进废纸篓）。")
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.secondary)
            }

            if let error = session.errorMessage {
                Text(error)
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.orange)
            }

            CleanCandidatesOutlineList(
                groups: presented.groups,
                selectedIDs: $session.selectedIDs,
                expandedCategories: $expandedCategories
            )

            CleanCandidatesPaginationBar(
                page: presented.page,
                pageSize: $pageSize,
                onPageChange: { page = $0 }
            )
            .onChange(of: pageSize) { _, _ in page = 1 }

            CleanCandidatesFooter(
                canClean: !session.selectedIDs.isEmpty,
                onRescan: { session.startScan() },
                onClean: { confirm = true }
            )
        }
        .padding(VoleTheme.Spacing.xl)
        .background(VoleTheme.Colors.contentBackground)
        .confirmationDialog(
            selectedPrivilegedCount > 0
                ? "个人文件移到废纸篓；需管理员权限的文件经 root权限助手永久删除（未就绪则跳过）"
                : "将把已选项目移到废纸篓",
            isPresented: $confirm,
            titleVisibility: .visible
        ) {
            Button("确认清理", role: .destructive) { session.applySelected() }
            Button("取消", role: .cancel) {}
        }
        .onAppear {
            if expandedCategories.isEmpty, let first = presented.groups.first {
                expandedCategories = [first.id]
            }
        }
    }
}

// MARK: - Sections

private struct CleanCandidatesHeader: View {
    let selectedCount: Int
    let totalCount: Int
    let selectedBytes: UInt64
    let onSelectAll: () -> Void
    let onSelectNone: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: VoleTheme.Spacing.xs) {
                Text("Candidates · 候选")
                    .font(VoleTheme.TypeScale.eyebrow())
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
                Text("挑要清掉的")
                    .font(VoleTheme.TypeScale.title())
                    .foregroundStyle(VoleTheme.Colors.text)
                Text("\(CandidateListPresentation.selectionCountCaption(selected: selectedCount, total: totalCount)) 项")
                    .font(VoleTheme.TypeScale.metric())
                    .foregroundStyle(VoleTheme.Colors.text)
                Text("已选 / 总计")
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: VoleTheme.Spacing.md)
            VStack(alignment: .trailing, spacing: VoleTheme.Spacing.xs) {
                HStack(spacing: VoleTheme.Spacing.sm) {
                    Button("全选", action: onSelectAll)
                    Button("全不选", action: onSelectNone)
                }
                Text(ByteFormat.string(selectedBytes))
                    .font(VoleTheme.TypeScale.metricLarge())
                    .foregroundStyle(VoleTheme.Colors.text)
                    .monospacedDigit()
                Text("已选大小")
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct CleanCandidatesFilterBar: View {
    @Binding var searchText: String
    @Binding var sizeFilter: CandidateSizeFilter
    @Binding var rootOnly: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.sm) {
            HStack(spacing: VoleTheme.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索文件或路径", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, VoleTheme.Spacing.md)
            .padding(.vertical, VoleTheme.Spacing.sm)
            .background(VoleTheme.Colors.molehill.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: VoleTheme.Radius.control))

            HStack(spacing: VoleTheme.Spacing.sm) {
                Picker("大小", selection: $sizeFilter) {
                    ForEach(CandidateSizeFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                Toggle("仅需 root", isOn: $rootOnly)
                    .toggleStyle(.switch)
                    .font(VoleTheme.TypeScale.caption())
                    .fixedSize()

                Text("按大小 ↓")
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, VoleTheme.Spacing.sm)
                    .padding(.vertical, 6)
                    .background(VoleTheme.Colors.molehill.opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: VoleTheme.Radius.control))
            }
        }
    }
}

private struct CleanCandidatesOutlineList: View {
    let groups: [CandidateGroup]
    @Binding var selectedIDs: Set<String>
    @Binding var expandedCategories: Set<String>

    var body: some View {
        List {
            HStack {
                Text("名称")
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("大小")
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            ForEach(groups) { group in
                CleanCandidateGroupRow(
                    group: group,
                    selectedIDs: $selectedIDs,
                    isExpanded: Binding(
                        get: { expandedCategories.contains(group.id) },
                        set: { expanded in
                            if expanded {
                                expandedCategories.insert(group.id)
                            } else {
                                expandedCategories.remove(group.id)
                            }
                        }
                    )
                )
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }
}

private struct CleanCandidateGroupRow: View {
    let group: CandidateGroup
    @Binding var selectedIDs: Set<String>
    @Binding var isExpanded: Bool

    private var selectedInGroup: Int {
        group.selectedCount(in: selectedIDs)
    }

    private var groupBinding: Binding<Bool> {
        Binding(
            get: { selectedInGroup == group.entries.count && !group.entries.isEmpty },
            set: { on in
                var next = selectedIDs
                if on {
                    group.entries.forEach { next.insert($0.id) }
                } else {
                    group.entries.forEach { next.remove($0.id) }
                }
                selectedIDs = next
            }
        )
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(group.pageEntries) { entry in
                CleanCandidateLeafRow(entry: entry, selectedIDs: $selectedIDs)
            }
        } label: {
            HStack(spacing: VoleTheme.Spacing.sm) {
                Toggle("", isOn: groupBinding)
                    .toggleStyle(.checkbox)
                    .labelsHidden()

                // 应用 logo + 名称 + 标签
                CandidateAppLogoView(lookup: group.iconLookup, size: 22)

                Text(group.app.title)
                    .font(VoleTheme.TypeScale.body().weight(.semibold))
                    .foregroundStyle(VoleTheme.Colors.text)
                    .lineLimit(1)

                CandidateAppTagBadge(
                    count: group.entries.count,
                    selectedCount: selectedInGroup
                )

                Spacer(minLength: 0)

                Text(group.sizeCaption(selectedIDs: selectedIDs))
                    .font(VoleTheme.TypeScale.metric())
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .listRowBackground(Color.clear)
    }
}

private struct CandidateAppTagBadge: View {
    let count: Int
    let selectedCount: Int

    var body: some View {
        Text("\(selectedCount)/\(count)")
            .font(VoleTheme.TypeScale.caption().weight(.semibold))
            .foregroundStyle(VoleTheme.Colors.onFur)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(VoleTheme.Colors.sage.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .accessibilityLabel("已选 \(selectedCount)，共 \(count) 项")
    }
}

private struct CleanCandidateLeafRow: View {
    let entry: VolePlanEntry
    @Binding var selectedIDs: Set<String>

    private var isPrivileged: Bool {
        PathAuthorization.requiresPrivilegedHelper(entry.path)
    }

    private var binding: Binding<Bool> {
        Binding(
            get: { selectedIDs.contains(entry.id) },
            set: { on in
                var next = selectedIDs
                if on { next.insert(entry.id) } else { next.remove(entry.id) }
                selectedIDs = next
            }
        )
    }

    var body: some View {
        Toggle(isOn: binding) {
            HStack(alignment: .firstTextBaseline, spacing: VoleTheme.Spacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: VoleTheme.Spacing.sm) {
                        Text(entry.label)
                            .font(VoleTheme.TypeScale.body().weight(.semibold))
                            .foregroundStyle(VoleTheme.Colors.text)
                        if isPrivileged {
                            Text("需 root")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(VoleTheme.Colors.soil)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(VoleTheme.Colors.molehill.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    Text(entry.path)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer(minLength: VoleTheme.Spacing.sm)
                Text(ByteFormat.string(entry.size))
                    .font(VoleTheme.TypeScale.metric())
                    .foregroundStyle(.secondary)
            }
        }
        .toggleStyle(.checkbox)
        .accessibilityLabel("\(entry.label)，\(ByteFormat.string(entry.size))")
        .accessibilityValue(selectedIDs.contains(entry.id) ? "已选" : "未选")
        .accessibilityHint(isPrivileged ? "需管理员权限，将经 root权限助手永久删除" : "移动到废纸篓")
        .listRowBackground(Color.clear)
    }
}

private struct CleanCandidatesPaginationBar: View {
    let page: CandidatePageSlice
    @Binding var pageSize: Int
    let onPageChange: (Int) -> Void

    private let pageSizeOptions = [20, 50, 100]

    var body: some View {
        HStack(spacing: VoleTheme.Spacing.sm) {
            Button {
                onPageChange(1)
            } label: {
                Image(systemName: "chevron.backward.to.line")
            }
            .disabled(page.page <= 1)

            Button {
                onPageChange(page.page - 1)
            } label: {
                Image(systemName: "chevron.backward")
            }
            .disabled(page.page <= 1)

            ForEach(visiblePageNumbers, id: \.self) { number in
                Button("\(number)") {
                    onPageChange(number)
                }
                .buttonStyle(.bordered)
                .tint(number == page.page ? VoleTheme.Colors.fur : nil)
                .disabled(number == page.page)
            }

            Button {
                onPageChange(page.page + 1)
            } label: {
                Image(systemName: "chevron.forward")
            }
            .disabled(page.page >= page.pageCount)

            Button {
                onPageChange(page.pageCount)
            } label: {
                Image(systemName: "chevron.forward.to.line")
            }
            .disabled(page.page >= page.pageCount)

            Picker("每页", selection: $pageSize) {
                ForEach(pageSizeOptions, id: \.self) { size in
                    Text("\(size) 项").tag(size)
                }
            }
            .labelsHidden()
            .frame(width: 96)

            Spacer(minLength: 0)

            Text(page.rangeDescription)
                .font(VoleTheme.TypeScale.caption())
                .foregroundStyle(.secondary)
        }
    }

    private var visiblePageNumbers: [Int] {
        let count = page.pageCount
        guard count > 0 else { return [1] }
        let start = max(1, page.page - 1)
        let end = min(count, start + 2)
        return Array(start...end)
    }
}

private struct CleanCandidatesFooter: View {
    let canClean: Bool
    let onRescan: () -> Void
    let onClean: () -> Void

    var body: some View {
        HStack(spacing: VoleTheme.Spacing.md) {
            Button("重新扫描", action: onRescan)
            Button("清理到废纸篓", action: onClean)
                .buttonStyle(.borderedProminent)
                .tint(VoleTheme.Colors.soil)
                .keyboardShortcut(.defaultAction)
                .disabled(!canClean)
            Spacer()
            Text("Enter · 默认动作")
                .font(VoleTheme.TypeScale.caption())
                .foregroundStyle(.tertiary)
        }
    }
}
