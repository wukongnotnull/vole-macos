import SwiftUI

func selectedTotalBytes(entries: [VolePlanEntry], selectedIDs: Set<String>) -> UInt64 {
    entries.reduce(0) { $0 + (selectedIDs.contains($1.id) ? $1.size : 0) }
}

func strataFraction(entries: [VolePlanEntry], selectedIDs: Set<String>) -> Double {
    let total = entries.reduce(UInt64(0)) { $0 + $1.size }
    guard total > 0 else { return 0 }
    return Double(selectedTotalBytes(entries: entries, selectedIDs: selectedIDs)) / Double(total)
}

/// Coarsened viewport breakpoints for Clean candidates chrome.
struct CleanCandidatesLayoutMetrics: Equatable {
    var isWide: Bool
    var isTall: Bool

    var contentPadding: CGFloat {
        isTall ? VoleTheme.Spacing.xl : VoleTheme.Spacing.md
    }

    var sectionSpacing: CGFloat {
        isTall ? VoleTheme.Spacing.md : VoleTheme.Spacing.sm
    }

    /// Brand eyebrow stays visible in dense short layouts; only caption densifies.
    var showsEyebrow: Bool { true }

    static func resolve(width: CGFloat, height: CGFloat) -> CleanCandidatesLayoutMetrics {
        CleanCandidatesLayoutMetrics(
            isWide: width >= 680,
            isTall: height >= 540
        )
    }
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
    @State private var layout = CleanCandidatesLayoutMetrics(isWide: true, isTall: true)

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
        VStack(alignment: .leading, spacing: layout.sectionSpacing) {
            // Top chrome keeps intrinsic height — never compress when the list wants space.
            VStack(alignment: .leading, spacing: layout.sectionSpacing) {
                CleanCandidatesHeader(
                    selectedCount: session.selectedIDs.count,
                    totalCount: session.entries.count,
                    selectedBytes: selectedBytes,
                    isWide: layout.isWide,
                    isTall: layout.isTall,
                    showsEyebrow: layout.showsEyebrow,
                    onSelectAll: { session.selectedIDs = Set(session.entries.map(\.id)) },
                    onSelectNone: { session.selectedIDs = [] }
                )

                CleanCandidatesFilterBar(
                    searchText: $searchText,
                    sizeFilter: $sizeFilter,
                    rootOnly: $rootOnly,
                    isWide: layout.isWide
                )
                .onChange(of: searchText) { _, _ in page = 1 }
                .onChange(of: sizeFilter) { _, _ in page = 1 }
                .onChange(of: rootOnly) { _, _ in page = 1 }

                if selectedPrivilegedCount > 0 && !helperStatus.isReady {
                    Text("已选含 \(selectedPrivilegedCount) 项系统级文件，需开启 Root 权限才能永久删除，否则将跳过。")
                        .font(VoleTheme.TypeScale.caption())
                        .foregroundStyle(.orange)
                        .lineLimit(layout.isTall ? 3 : 2)
                        .fixedSize(horizontal: false, vertical: true)
                } else if selectedPrivilegedCount > 0 {
                    Text("已选含 \(selectedPrivilegedCount) 项系统级文件，将经 Root 权限永久删除（不进废纸篓）。")
                        .font(VoleTheme.TypeScale.caption())
                        .foregroundStyle(.secondary)
                        .lineLimit(layout.isTall ? 3 : 2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let error = session.errorMessage {
                    Text(error)
                        .font(VoleTheme.TypeScale.caption())
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .layoutPriority(1)

            // List is the only flexible region; minHeight 0 lets it shrink with the window.
            CleanCandidatesOutlineList(
                groups: presented.groups,
                selectedIDs: $session.selectedIDs,
                expandedCategories: $expandedCategories
            )
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
            .layoutPriority(0)

            VStack(alignment: .leading, spacing: layout.sectionSpacing) {
                CleanCandidatesPaginationBar(
                    page: presented.page,
                    pageSize: $pageSize,
                    isWide: layout.isWide,
                    onPageChange: { page = $0 }
                )
                .onChange(of: pageSize) { _, _ in page = 1 }

                CleanCandidatesFooter(
                    canClean: !session.selectedIDs.isEmpty,
                    isWide: layout.isWide,
                    onRescan: { session.startScan() },
                    onClean: { confirm = true }
                )
            }
            .fixedSize(horizontal: false, vertical: true)
            .layoutPriority(1)
        }
        .padding(layout.contentPadding)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        .background(VoleTheme.Colors.contentBackground)
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { size in
            let next = CleanCandidatesLayoutMetrics.resolve(width: size.width, height: size.height)
            if next != layout {
                layout = next
            }
        }
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
    let isWide: Bool
    let isTall: Bool
    let showsEyebrow: Bool
    let onSelectAll: () -> Void
    let onSelectNone: () -> Void

    var body: some View {
        if isTall {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: VoleTheme.Spacing.md) {
                    CleanCandidatesHeaderTitle(
                        selectedCount: selectedCount,
                        totalCount: totalCount,
                        showEyebrow: showsEyebrow,
                        showCaption: true
                    )
                    Spacer(minLength: VoleTheme.Spacing.sm)
                    CleanCandidatesHeaderMetrics(
                        selectedBytes: selectedBytes,
                        alignTrailing: true,
                        compact: false,
                        onSelectAll: onSelectAll,
                        onSelectNone: onSelectNone
                    )
                }

                VStack(alignment: .leading, spacing: VoleTheme.Spacing.sm) {
                    CleanCandidatesHeaderTitle(
                        selectedCount: selectedCount,
                        totalCount: totalCount,
                        showEyebrow: showsEyebrow,
                        showCaption: true
                    )
                    CleanCandidatesHeaderMetrics(
                        selectedBytes: selectedBytes,
                        alignTrailing: false,
                        compact: false,
                        onSelectAll: onSelectAll,
                        onSelectNone: onSelectNone
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        } else {
            // Short window: keep brand eyebrow; densify caption/metrics only.
            HStack(alignment: .top, spacing: VoleTheme.Spacing.md) {
                CleanCandidatesHeaderTitle(
                    selectedCount: selectedCount,
                    totalCount: totalCount,
                    showEyebrow: showsEyebrow,
                    showCaption: false
                )
                Spacer(minLength: VoleTheme.Spacing.sm)
                CleanCandidatesHeaderMetrics(
                    selectedBytes: selectedBytes,
                    alignTrailing: isWide,
                    compact: true,
                    onSelectAll: onSelectAll,
                    onSelectNone: onSelectNone
                )
            }
        }
    }
}

private struct CleanCandidatesHeaderTitle: View {
    let selectedCount: Int
    let totalCount: Int
    let showEyebrow: Bool
    let showCaption: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: VoleTheme.Spacing.xs) {
            if showEyebrow {
                Text("Candidates · 候选")
                    .font(VoleTheme.TypeScale.eyebrow())
                    .tracking(VoleTheme.TypeScale.eyebrowTracking)
                    .foregroundStyle(.secondary)
            }
            Text("挑要清掉的")
                .font(showEyebrow ? VoleTheme.TypeScale.title() : VoleTheme.TypeScale.headline())
                .tracking(showEyebrow ? VoleTheme.TypeScale.titleTracking : 0)
                .foregroundStyle(VoleTheme.Colors.text)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Text("\(CandidateListPresentation.selectionCountCaption(selected: selectedCount, total: totalCount)) 项")
                .font(VoleTheme.TypeScale.metric())
                .foregroundStyle(VoleTheme.Colors.text)
            if showCaption {
                Text("已选 / 总计")
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct CleanCandidatesHeaderMetrics: View {
    let selectedBytes: UInt64
    let alignTrailing: Bool
    let compact: Bool
    let onSelectAll: () -> Void
    let onSelectNone: () -> Void

    var body: some View {
        VStack(alignment: alignTrailing ? .trailing : .leading, spacing: VoleTheme.Spacing.xs) {
            HStack(spacing: VoleTheme.Spacing.sm) {
                Button("全选", action: onSelectAll)
                Button("全不选", action: onSelectNone)
            }
            Text(ByteFormat.string(selectedBytes))
                .font(compact ? VoleTheme.TypeScale.metric() : VoleTheme.TypeScale.metricLarge())
                .foregroundStyle(VoleTheme.Colors.text)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            if !compact {
                Text("已选大小")
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(.secondary)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

private struct CleanCandidatesFilterBar: View {
    @Binding var searchText: String
    @Binding var sizeFilter: CandidateSizeFilter
    @Binding var rootOnly: Bool
    let isWide: Bool

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: VoleTheme.Spacing.sm) {
                CleanCandidatesSearchField(text: $searchText)
                    .frame(minWidth: 120, maxWidth: .infinity)
                CleanCandidatesFilterControls(
                    sizeFilter: $sizeFilter,
                    rootOnly: $rootOnly,
                    compactSizePicker: !isWide
                )
            }

            VStack(alignment: .leading, spacing: VoleTheme.Spacing.sm) {
                CleanCandidatesSearchField(text: $searchText)
                CleanCandidatesFilterControls(
                    sizeFilter: $sizeFilter,
                    rootOnly: $rootOnly,
                    compactSizePicker: true
                )
            }
        }
    }
}

private struct CleanCandidatesSearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: VoleTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("搜索文件或路径", text: $text)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, VoleTheme.Spacing.md)
        .padding(.vertical, VoleTheme.Spacing.sm)
        .background(CleanCandidatesListStyle.searchFieldFill)
        .clipShape(RoundedRectangle(cornerRadius: VoleTheme.Radius.control))
    }
}

private struct CleanCandidatesFilterControls: View {
    @Binding var sizeFilter: CandidateSizeFilter
    @Binding var rootOnly: Bool
    let compactSizePicker: Bool

    var body: some View {
        HStack(spacing: VoleTheme.Spacing.sm) {
            if compactSizePicker {
                Picker("大小", selection: $sizeFilter) {
                    ForEach(CandidateSizeFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .tint(CleanCandidatesListStyle.selectionFill)
                .fixedSize()
            } else {
                HStack(spacing: VoleTheme.Spacing.xs) {
                    ForEach(CandidateSizeFilter.allCases) { filter in
                        CleanCandidatesSizeChip(
                            title: filter.title,
                            isSelected: sizeFilter == filter
                        ) {
                            sizeFilter = filter
                        }
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
            }

            Toggle("仅需 root", isOn: $rootOnly)
                .toggleStyle(.switch)
                .tint(CleanCandidatesListStyle.selectionFill)
                .font(VoleTheme.TypeScale.caption())
                .fixedSize()

            Text("按大小 ↓")
                .font(VoleTheme.TypeScale.caption())
                .foregroundStyle(CleanCandidatesListStyle.filterChipIdleLabel)
                .padding(.horizontal, VoleTheme.Spacing.sm)
                .padding(.vertical, 6)
                .background(CleanCandidatesListStyle.sortChipFill)
                .clipShape(RoundedRectangle(cornerRadius: VoleTheme.Radius.control))
                .fixedSize()
        }
    }
}

private struct CleanCandidatesSizeChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(VoleTheme.TypeScale.caption().weight(isSelected ? .semibold : .regular))
                .foregroundStyle(
                    isSelected
                        ? CleanCandidatesListStyle.filterChipSelectedLabel
                        : CleanCandidatesListStyle.filterChipIdleLabel
                )
                .padding(.horizontal, VoleTheme.Spacing.sm)
                .padding(.vertical, 6)
                .background(
                    isSelected
                        ? CleanCandidatesListStyle.filterChipSelectedFill
                        : CleanCandidatesListStyle.filterChipIdleFill
                )
                .clipShape(RoundedRectangle(cornerRadius: VoleTheme.Radius.control))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
                    .foregroundStyle(CleanCandidatesListStyle.columnHeaderLabel)
                Spacer()
                Text("大小")
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(CleanCandidatesListStyle.columnHeaderLabel)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(
                EdgeInsets(
                    top: CleanCandidatesListStyle.rowVerticalPadding,
                    leading: VoleTheme.Spacing.sm,
                    bottom: CleanCandidatesListStyle.rowVerticalPadding,
                    trailing: VoleTheme.Spacing.sm
                )
            )

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
        .listRowSeparatorTint(CleanCandidatesListStyle.rowSeparator)
        .background(Color.clear)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
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
                Toggle(isOn: groupBinding) {
                    EmptyView()
                }
                .toggleStyle(VoleCircularCheckboxStyle())

                Text(group.app.title)
                    .font(VoleTheme.TypeScale.body().weight(.semibold))
                    .foregroundStyle(VoleTheme.Colors.text)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Text(group.sizeCaption(selectedIDs: selectedIDs))
                    .font(VoleTheme.TypeScale.metric())
                    .foregroundStyle(CleanCandidatesListStyle.sizeLabel)
                    .monospacedDigit()
                    .layoutPriority(1)
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(
            EdgeInsets(
                top: CleanCandidatesListStyle.rowVerticalPadding,
                leading: VoleTheme.Spacing.sm,
                bottom: CleanCandidatesListStyle.rowVerticalPadding,
                trailing: VoleTheme.Spacing.sm
            )
        )
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
                            .lineLimit(1)
                        if isPrivileged {
                            Text("需 root")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(VoleTheme.Colors.soil)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(VoleTheme.Colors.molehill.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: VoleTheme.Radius.strata))
                        }
                    }
                    Text(entry.path)
                        .font(VoleTheme.TypeScale.caption().monospaced())
                        .foregroundStyle(CleanCandidatesListStyle.pathLabel)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer(minLength: VoleTheme.Spacing.sm)
                Text(ByteFormat.string(entry.size))
                    .font(VoleTheme.TypeScale.metric())
                    .foregroundStyle(CleanCandidatesListStyle.sizeLabel)
                    .layoutPriority(1)
            }
        }
        .toggleStyle(VoleCircularCheckboxStyle())
        .accessibilityLabel("\(entry.label)，\(ByteFormat.string(entry.size))")
        .accessibilityValue(selectedIDs.contains(entry.id) ? "已选" : "未选")
        .accessibilityHint(isPrivileged ? "需管理员权限，将经 root权限助手永久删除" : "移动到废纸篓")
        .listRowBackground(Color.clear)
        .listRowInsets(
            EdgeInsets(
                top: CleanCandidatesListStyle.rowVerticalPadding,
                leading: VoleTheme.Spacing.sm,
                bottom: CleanCandidatesListStyle.rowVerticalPadding,
                trailing: VoleTheme.Spacing.sm
            )
        )
    }
}

private struct CleanCandidatesPaginationBar: View {
    let page: CandidatePageSlice
    @Binding var pageSize: Int
    let isWide: Bool
    let onPageChange: (Int) -> Void

    private let pageSizeOptions = [20, 50, 100]

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: VoleTheme.Spacing.sm) {
                pageControls
                pageSizePicker
                Spacer(minLength: 0)
                rangeLabel
            }

            VStack(alignment: .leading, spacing: VoleTheme.Spacing.xs) {
                HStack(spacing: VoleTheme.Spacing.sm) {
                    pageControls
                    pageSizePicker
                }
                rangeLabel
            }
        }
    }

    private var pageControls: some View {
        HStack(spacing: VoleTheme.Spacing.sm) {
            pageNavButton(systemName: "chevron.backward.to.line", disabled: page.page <= 1) {
                onPageChange(1)
            }
            pageNavButton(systemName: "chevron.backward", disabled: page.page <= 1) {
                onPageChange(page.page - 1)
            }

            if isWide {
                ForEach(visiblePageNumbers, id: \.self) { number in
                    Button("\(number)") {
                        onPageChange(number)
                    }
                    .buttonStyle(.bordered)
                    .tint(number == page.page ? CleanCandidatesListStyle.selectionFill : nil)
                    .disabled(number == page.page)
                }
            } else {
                Text("\(page.page) / \(max(page.pageCount, 1))")
                    .font(VoleTheme.TypeScale.caption())
                    .foregroundStyle(CleanCandidatesListStyle.columnHeaderLabel)
                    .monospacedDigit()
                    .frame(minWidth: 44)
            }

            pageNavButton(systemName: "chevron.forward", disabled: page.page >= page.pageCount) {
                onPageChange(page.page + 1)
            }
            pageNavButton(systemName: "chevron.forward.to.line", disabled: page.page >= page.pageCount) {
                onPageChange(page.pageCount)
            }
        }
    }

    private func pageNavButton(
        systemName: String,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
        }
        .buttonStyle(.bordered)
        .disabled(disabled)
    }

    private var pageSizePicker: some View {
        Picker("每页", selection: $pageSize) {
            ForEach(pageSizeOptions, id: \.self) { size in
                Text("\(size) 项").tag(size)
            }
        }
        .labelsHidden()
        .frame(width: 96)
    }

    private var rangeLabel: some View {
        Text(page.rangeDescription)
            .font(VoleTheme.TypeScale.caption())
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
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
    let isWide: Bool
    let onRescan: () -> Void
    let onClean: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: VoleTheme.Spacing.md) {
                actionButtons
                Spacer(minLength: 0)
                if isWide {
                    hintLabel
                }
            }

            VStack(alignment: .leading, spacing: VoleTheme.Spacing.sm) {
                actionButtons
                if isWide {
                    hintLabel
                }
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: VoleTheme.Spacing.md) {
            Button("重新扫描", action: onRescan)
            Button("清理到废纸篓", action: onClean)
                .buttonStyle(.borderedProminent)
                .tint(VoleTheme.Colors.soil)
                .keyboardShortcut(.defaultAction)
                .disabled(!canClean)
        }
    }

    private var hintLabel: some View {
        Text("Enter · 默认动作")
            .font(VoleTheme.TypeScale.caption())
            .foregroundStyle(.tertiary)
    }
}
