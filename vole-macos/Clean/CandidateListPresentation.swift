import Foundation

struct CandidateAppGroup: Identifiable, Equatable, Hashable {
    var id: String
    var title: String
    var systemImage: String
    var bundleIdentifier: String? = nil

    static let other = CandidateAppGroup(
        id: "other",
        title: "其他",
        systemImage: "app.dashed"
    )
}

enum CandidateAppIconLookup: Equatable {
    case bundleIdentifier(String)
    case applicationPath(String)
    case systemSymbol(String)
}

enum CandidateSort: Equatable {
    case sizeDescending
}

struct CandidateListQuery: Equatable {
    var searchText: String = ""
    var minBytes: UInt64 = 0
    var rootOnly: Bool = false
}

struct CandidateGroup: Identifiable, Equatable {
    var app: CandidateAppGroup
    /// All filtered entries in this app group (for totals / group select).
    var entries: [VolePlanEntry]
    /// Entries visible on the current page (for outline leaves).
    var pageEntries: [VolePlanEntry]

    var id: String { app.id }

    var totalBytes: UInt64 {
        entries.reduce(0) { $0 + $1.size }
    }

    func selectedCount(in selectedIDs: Set<String>) -> Int {
        entries.reduce(0) { $0 + (selectedIDs.contains($1.id) ? 1 : 0) }
    }

    func selectedBytes(in selectedIDs: Set<String>) -> UInt64 {
        entries.reduce(0) { $0 + (selectedIDs.contains($1.id) ? $1.size : 0) }
    }

    /// When the group is not fully selected, show `selected / total`; otherwise total only.
    func sizeCaption(selectedIDs: Set<String>) -> String {
        let selected = selectedCount(in: selectedIDs)
        let total = ByteFormat.string(totalBytes)
        if selected < entries.count {
            return "\(ByteFormat.string(selectedBytes(in: selectedIDs))) / \(total)"
        }
        return total
    }
}

struct CandidatePageSlice: Equatable {
    var items: [VolePlanEntry]
    var page: Int
    var pageSize: Int
    var totalCount: Int

    var pageCount: Int {
        guard pageSize > 0 else { return 0 }
        return max(1, Int(ceil(Double(totalCount) / Double(pageSize))))
    }

    var rangeDescription: String {
        guard totalCount > 0, !items.isEmpty else {
            return "0 项，共 \(totalCount) 项"
        }
        let start = (page - 1) * pageSize + 1
        let end = start + items.count - 1
        return "\(start)-\(end) 项，共 \(totalCount) 项"
    }
}

struct CandidateListPresented: Equatable {
    var groups: [CandidateGroup]
    var page: CandidatePageSlice
    var filteredCount: Int
}

enum CandidateListPresentation {
    private static let junkTokens: Set<String> = [
        "cache", "caches", "data", "log", "logs", "old", "version", "versions",
        "model", "models", "temp", "tmp", "support", "application",
    ]

    private static let knownApps: [(
        needles: [String],
        id: String,
        title: String,
        icon: String,
        bundleIdentifier: String?
    )] = [
        (
            ["vs code", "vscode", "com.microsoft.vscode", "/code/cache", "/code/cacheddata", "application support/code"],
            "vscode", "VS Code", "chevron.left.forwardslash.chevron.right", "com.microsoft.VSCode"
        ),
        (["xcode", "deriveddata", "com.apple.dt.xcode"], "xcode", "Xcode", "hammer", "com.apple.dt.Xcode"),
        (["safari", "com.apple.safari"], "safari", "Safari", "safari", "com.apple.Safari"),
        (["chrome", "com.google.chrome", "chromium"], "chrome", "Chrome", "globe", "com.google.Chrome"),
        (["firefox", "org.mozilla.firefox"], "firefox", "Firefox", "globe", "org.mozilla.firefox"),
        (["edge", "com.microsoft.edgemac"], "edge", "Edge", "globe", "com.microsoft.edgemac"),
        (["claude code", "claude"], "claude-code", "Claude Code", "brain", nil),
        (["ollama"], "ollama", "Ollama", "brain", nil),
        (["cursor"], "cursor", "Cursor", "chevron.left.forwardslash.chevron.right", "com.todesktop.230313mzl4w4u92"),
        (["slack"], "slack", "Slack", "bubble.left.and.bubble.right", "com.tinyspeck.slackmacgap"),
        (["discord"], "discord", "Discord", "bubble.left.and.bubble.right", "com.hnc.Discord"),
        (["wechat", "微信"], "wechat", "微信", "bubble.left.and.bubble.right", "com.tencent.xinWeChat"),
        (["docker"], "docker", "Docker", "shippingbox", "com.docker.docker"),
        (["node", "npm", "yarn", "pnpm", "node_modules"], "node", "Node.js", "chevron.left.forwardslash.chevron.right", nil),
        (["cocoapods", "swiftpm"], "apple-dev-tools", "Apple 开发工具", "hammer", "com.apple.dt.Xcode"),
        (["jianying", "capcut", "剪映"], "jianying", "剪映", "app", "com.lemon.lvoverseas"),
    ]

    static func selectionCountCaption(selected: Int, total: Int) -> String {
        "\(selected) / \(total)"
    }

    static func appGroup(for entry: VolePlanEntry) -> CandidateAppGroup {
        let haystack = "\(entry.path) \(entry.label) \(entry.ruleID)".lowercased()

        for app in knownApps {
            if app.needles.contains(where: { haystack.contains($0) }) {
                return CandidateAppGroup(
                    id: app.id,
                    title: app.title,
                    systemImage: app.icon,
                    bundleIdentifier: app.bundleIdentifier
                )
            }
        }

        if let bundleApp = appFromBundleID(in: entry.path) {
            return bundleApp
        }

        if let fromLabel = appFromLabel(entry.label) {
            return fromLabel
        }

        return .other
    }

    static func iconLookup(
        for app: CandidateAppGroup,
        entries: [VolePlanEntry]
    ) -> CandidateAppIconLookup {
        if let bundleID = app.bundleIdentifier, !bundleID.isEmpty {
            return .bundleIdentifier(bundleID)
        }
        for entry in entries {
            if let bundleID = bundleID(in: entry.path) {
                return .bundleIdentifier(bundleID)
            }
            if entry.path.hasSuffix(".app") || entry.path.contains(".app/") {
                let appPath = entry.path.components(separatedBy: ".app").first.map { $0 + ".app" }
                if let appPath {
                    return .applicationPath(appPath)
                }
            }
        }
        return .systemSymbol(app.systemImage)
    }

    static func groupEntries(_ entries: [VolePlanEntry]) -> [CandidateGroup] {
        groupEntries(entries, pageEntryIDs: Set(entries.map(\.id)))
    }

    static func groupEntries(
        _ entries: [VolePlanEntry],
        pageEntryIDs: Set<String>
    ) -> [CandidateGroup] {
        var buckets: [String: (app: CandidateAppGroup, entries: [VolePlanEntry])] = [:]
        for entry in entries {
            let app = appGroup(for: entry)
            var bucket = buckets[app.id] ?? (app: app, entries: [])
            bucket.entries.append(entry)
            buckets[app.id] = bucket
        }
        return buckets.values.compactMap { bucket in
            let pageItems = bucket.entries.filter { pageEntryIDs.contains($0.id) }
            guard !pageItems.isEmpty else { return nil }
            return CandidateGroup(app: bucket.app, entries: bucket.entries, pageEntries: pageItems)
        }
        .sorted { lhs, rhs in
            if lhs.totalBytes == rhs.totalBytes {
                return lhs.app.title.localizedStandardCompare(rhs.app.title) == .orderedAscending
            }
            return lhs.totalBytes > rhs.totalBytes
        }
    }

    static func filterEntries(_ entries: [VolePlanEntry], query: CandidateListQuery) -> [VolePlanEntry] {
        let needle = query.searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return entries.filter { entry in
            if entry.size < query.minBytes { return false }
            if query.rootOnly && !PathAuthorization.requiresPrivilegedHelper(entry.path) {
                return false
            }
            guard !needle.isEmpty else { return true }
            let app = appGroup(for: entry)
            return entry.label.lowercased().contains(needle)
                || entry.path.lowercased().contains(needle)
                || entry.ruleID.lowercased().contains(needle)
                || app.title.lowercased().contains(needle)
        }
    }

    static func sortEntries(_ entries: [VolePlanEntry], by sort: CandidateSort) -> [VolePlanEntry] {
        switch sort {
        case .sizeDescending:
            return entries.sorted { lhs, rhs in
                if lhs.size == rhs.size { return lhs.id < rhs.id }
                return lhs.size > rhs.size
            }
        }
    }

    static func pageSlice(_ entries: [VolePlanEntry], page: Int, pageSize: Int) -> CandidatePageSlice {
        let safePageSize = max(pageSize, 1)
        let pageCount = max(1, Int(ceil(Double(entries.count) / Double(safePageSize))))
        let safePage = min(max(page, 1), pageCount)
        let start = (safePage - 1) * safePageSize
        let end = min(start + safePageSize, entries.count)
        let items = start < end ? Array(entries[start..<end]) : []
        return CandidatePageSlice(
            items: items,
            page: safePage,
            pageSize: safePageSize,
            totalCount: entries.count
        )
    }

    static func present(
        entries: [VolePlanEntry],
        query: CandidateListQuery,
        page: Int,
        pageSize: Int,
        sort: CandidateSort = .sizeDescending
    ) -> CandidateListPresented {
        let filtered = sortEntries(filterEntries(entries, query: query), by: sort)
        let slice = pageSlice(filtered, page: page, pageSize: pageSize)
        let pageIDs = Set(slice.items.map(\.id))
        return CandidateListPresented(
            groups: groupEntries(filtered, pageEntryIDs: pageIDs),
            page: slice,
            filteredCount: filtered.count
        )
    }

    static func bundleID(in path: String) -> String? {
        let parts = path.split(separator: "/").map(String.init)
        return parts.last(where: isBundleIdentifier(_:))
    }

    private static func appFromBundleID(in path: String) -> CandidateAppGroup? {
        guard let bundle = bundleID(in: path) else { return nil }
        let last = bundle.split(separator: ".").last.map(String.init) ?? bundle
        let title = prettyTitle(from: last)
        return CandidateAppGroup(
            id: bundle.lowercased(),
            title: title,
            systemImage: "app",
            bundleIdentifier: bundle
        )
    }

    private static func appFromLabel(_ label: String) -> CandidateAppGroup? {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let tokens = trimmed
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }

        let kept = tokens.filter { !junkTokens.contains($0.lowercased()) }
        let source = kept.isEmpty ? tokens : kept
        guard !source.isEmpty else { return nil }

        let title = source.joined(separator: " ")
        return CandidateAppGroup(
            id: title.lowercased(),
            title: title,
            systemImage: "app"
        )
    }

    private static func isBundleIdentifier(_ candidate: String) -> Bool {
        let pieces = candidate.split(separator: ".")
        guard pieces.count >= 3 else { return false }
        return candidate.allSatisfy { $0.isLetter || $0.isNumber || $0 == "." || $0 == "-" }
    }

    private static func prettyTitle(from raw: String) -> String {
        let spaced = raw
            .replacingOccurrences(
                of: "([a-z])([A-Z])",
                with: "$1 $2",
                options: .regularExpression
            )
        return spaced.prefix(1).uppercased() + spaced.dropFirst()
    }
}
