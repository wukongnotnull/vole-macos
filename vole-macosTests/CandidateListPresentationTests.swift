import XCTest
@testable import vole_macos

final class CandidateListPresentationTests: XCTestCase {
    private func entry(
        id: String,
        path: String,
        label: String,
        size: UInt64,
        ruleID: String = "r"
    ) -> VolePlanEntry {
        VolePlanEntry(
            id: id,
            path: path,
            label: label,
            size: size,
            ruleID: ruleID,
            skipReason: nil,
            dev: 0,
            ino: 0,
            mtime: 0
        )
    }

    func test_selectionCountCaption_showsSelectedOverTotal() {
        XCTAssertEqual(
            CandidateListPresentation.selectionCountCaption(selected: 443, total: 2085),
            "443 / 2085"
        )
        XCTAssertEqual(
            CandidateListPresentation.selectionCountCaption(selected: 0, total: 10),
            "0 / 10"
        )
    }

    func test_appGroup_mergesVariantsOfSameApp() {
        let vsCodeCache = CandidateListPresentation.appGroup(
            for: entry(
                id: "1",
                path: "/Users/me/Library/Caches/com.microsoft.VSCode",
                label: "VS Code cache",
                size: 1
            )
        )
        let vsCodeData = CandidateListPresentation.appGroup(
            for: entry(
                id: "2",
                path: "/Users/me/Library/Application Support/Code/Cache",
                label: "VS Code data cache",
                size: 1
            )
        )
        XCTAssertEqual(vsCodeCache.id, vsCodeData.id)
        XCTAssertEqual(vsCodeCache.title, "VS Code")
        XCTAssertEqual(vsCodeCache.bundleIdentifier, "com.microsoft.VSCode")

        let xcode = CandidateListPresentation.appGroup(
            for: entry(
                id: "3",
                path: "/Users/me/Library/Developer/Xcode/DerivedData/A",
                label: "Xcode cache",
                size: 1
            )
        )
        XCTAssertEqual(xcode.title, "Xcode")
        XCTAssertEqual(xcode.bundleIdentifier, "com.apple.dt.Xcode")

        let safari = CandidateListPresentation.appGroup(
            for: entry(
                id: "4",
                path: "/Users/me/Library/Caches/com.apple.Safari",
                label: "Safari cache",
                size: 1
            )
        )
        XCTAssertEqual(safari.title, "Safari")
        XCTAssertEqual(safari.bundleIdentifier, "com.apple.Safari")

        let claude = CandidateListPresentation.appGroup(
            for: entry(
                id: "5",
                path: "/Users/me/Library/Caches/claude",
                label: "Claude Code old version",
                size: 1
            )
        )
        XCTAssertEqual(claude.title, "Claude Code")
    }

    func test_iconLookup_prefersKnownBundleThenPathBundleID() {
        let known = CandidateAppGroup(
            id: "chrome",
            title: "Chrome",
            systemImage: "globe",
            bundleIdentifier: "com.google.Chrome"
        )
        XCTAssertEqual(
            CandidateListPresentation.iconLookup(
                for: known,
                entries: [
                    entry(id: "1", path: "/Users/me/Library/Caches/foo", label: "Chrome", size: 1),
                ]
            ),
            .bundleIdentifier("com.google.Chrome")
        )

        let generic = CandidateAppGroup(id: "foo", title: "Foo", systemImage: "app")
        XCTAssertEqual(
            CandidateListPresentation.iconLookup(
                for: generic,
                entries: [
                    entry(
                        id: "2",
                        path: "/Users/me/Library/Caches/com.example.FooApp",
                        label: "Foo",
                        size: 1
                    ),
                ]
            ),
            .bundleIdentifier("com.example.FooApp")
        )

        XCTAssertEqual(
            CandidateListPresentation.iconLookup(for: .other, entries: []),
            .systemSymbol("app.dashed")
        )
    }

    func test_sizeCaption_showsSelectedOverTotalWhenNotFullySelected() {
        let entries = [
            entry(
                id: "a",
                path: "/Users/me/Library/Caches/com.microsoft.VSCode/a",
                label: "VS Code cache",
                size: 100
            ),
            entry(
                id: "b",
                path: "/Users/me/Library/Caches/com.microsoft.VSCode/b",
                label: "VS Code data cache",
                size: 50
            ),
        ]
        let group = CandidateListPresentation.groupEntries(entries)[0]

        XCTAssertEqual(group.sizeCaption(selectedIDs: ["a", "b"]), ByteFormat.string(150))
        XCTAssertEqual(
            group.sizeCaption(selectedIDs: ["a"]),
            "\(ByteFormat.string(100)) / \(ByteFormat.string(150))"
        )
        XCTAssertEqual(
            group.sizeCaption(selectedIDs: []),
            "\(ByteFormat.string(0)) / \(ByteFormat.string(150))"
        )
    }

    func test_groupEntries_aggregatesByAppAndSortsBySizeDescending() {
        let entries = [
            entry(
                id: "a",
                path: "/Users/me/Library/Caches/com.microsoft.VSCode",
                label: "VS Code cache",
                size: 100
            ),
            entry(
                id: "b",
                path: "/Users/me/Library/Developer/Xcode/DerivedData/b",
                label: "Xcode cache",
                size: 500
            ),
            entry(
                id: "c",
                path: "/Users/me/Library/Application Support/Code/Cache",
                label: "VS Code data cache",
                size: 50
            ),
            entry(
                id: "d",
                path: "/Users/me/Library/Caches/com.apple.Safari",
                label: "Safari cache",
                size: 10
            ),
        ]
        let groups = CandidateListPresentation.groupEntries(entries)
        XCTAssertEqual(groups.map(\.app.title), ["Xcode", "VS Code", "Safari"])
        XCTAssertEqual(groups[0].totalBytes, 500)
        XCTAssertEqual(groups[1].totalBytes, 150)
        XCTAssertEqual(groups[1].entries.map(\.id), ["a", "c"])
    }

    func test_filterEntries_appliesSearchSizeAndRootOnly() {
        let user = entry(id: "u", path: "/Users/me/Library/Caches/foo", label: "Foo cache", size: 200)
        let root = entry(id: "s", path: "/Library/Caches/bar", label: "Bar cache", size: 5_000_000)
        let tiny = entry(id: "t", path: "/Users/me/Library/Caches/tiny", label: "Tiny", size: 10)

        let filtered = CandidateListPresentation.filterEntries(
            [user, root, tiny],
            query: CandidateListQuery(searchText: "cache", minBytes: 100, rootOnly: true)
        )
        XCTAssertEqual(filtered.map(\.id), ["s"])
    }

    func test_sortEntries_bySizeDescending() {
        let a = entry(id: "a", path: "/Users/me/Library/Caches/a", label: "A", size: 10)
        let b = entry(id: "b", path: "/Users/me/Library/Caches/b", label: "B", size: 30)
        let c = entry(id: "c", path: "/Users/me/Library/Caches/c", label: "C", size: 20)
        let sorted = CandidateListPresentation.sortEntries([a, b, c], by: .sizeDescending)
        XCTAssertEqual(sorted.map(\.id), ["b", "c", "a"])
    }

    func test_pageSlice_returnsLeafWindowAndPageCount() {
        let entries = (0..<55).map { i in
            entry(id: "\(i)", path: "/Users/me/Library/Caches/\(i)", label: "L\(i)", size: UInt64(i))
        }
        let page1 = CandidateListPresentation.pageSlice(entries, page: 1, pageSize: 50)
        XCTAssertEqual(page1.items.count, 50)
        XCTAssertEqual(page1.totalCount, 55)
        XCTAssertEqual(page1.pageCount, 2)
        XCTAssertEqual(page1.rangeDescription, "1-50 项，共 55 项")

        let page2 = CandidateListPresentation.pageSlice(entries, page: 2, pageSize: 50)
        XCTAssertEqual(page2.items.count, 5)
        XCTAssertEqual(page2.rangeDescription, "51-55 项，共 55 项")
    }

    func test_present_composesFilterSortGroupAndPage() {
        let entries = [
            entry(
                id: "1",
                path: "/Users/me/Library/Caches/com.microsoft.VSCode",
                label: "VS Code cache",
                size: 200
            ),
            entry(
                id: "2",
                path: "/Library/Caches/com.apple.Safari",
                label: "Safari cache",
                size: 300
            ),
            entry(
                id: "3",
                path: "/Users/me/Library/Logs/c",
                label: "C",
                size: 50
            ),
            entry(
                id: "4",
                path: "/Users/me/Library/Application Support/Code/Cache",
                label: "VS Code data cache",
                size: 400
            ),
        ]
        let presented = CandidateListPresentation.present(
            entries: entries,
            query: CandidateListQuery(searchText: "", minBytes: 100, rootOnly: false),
            page: 1,
            pageSize: 2
        )
        // After filter (≥100): 1,2,4 — sorted by size: 4,2,1 — page 1 takes 4,2
        XCTAssertEqual(presented.page.items.map(\.id), ["4", "2"])
        XCTAssertEqual(presented.groups.map(\.app.title), ["VS Code", "Safari"])
        // Group totals use all filtered members; leaves are page-scoped.
        XCTAssertEqual(presented.groups[0].entries.map(\.id), ["4", "1"])
        XCTAssertEqual(presented.groups[0].pageEntries.map(\.id), ["4"])
        XCTAssertEqual(presented.filteredCount, 3)
    }
}
