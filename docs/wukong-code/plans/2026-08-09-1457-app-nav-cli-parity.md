# App Nav CLI Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use wukong-code:executing-plans (inline; default-yes) or wukong-code:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 CLI 已齐的 analyze / history / purge / installer 接进主侧栏可用面，并在设置中落地 Touch ID / 更新 / 自卸载。

**Architecture:** 扩展 `ShellModule` 与 `PlanModuleKind`；净化/安装包复用 `PlanModuleSession` 五态（可选 `--permanent`）；分析与历史各建 Session + RootView，消费 `analyze --json` / `history --json`；设置新增 `SettingsToolsModel` 编排 `touchid` / `update` / `remove`。不改兄弟仓协议；新 Swift 文件落在同步根组下，无需改 `pbxproj`。

**Tech Stack:** SwiftUI、XCTest、既有 `VoleProcess` / `PlanIO` / `PrivilegedApply` / `VoleTheme`。

## Global Constraints

- Spec：`docs/wukong-code/specs/2026-08-09-1454-app-nav-cli-parity-design.md`
- 侧栏顺序固定：清理 → 卸载 → 优化 → 净化 → 安装包 → 分析 → 历史 → 状态
- 协议只读现有 sidecar JSON/NDJSON；CLI 仓零改
- 无假数据：失败展示真实 sidecar 错误
- 视觉延续田鼠工坊（VoleTheme / SoilPanel）
- `--permanent` / `--purge-oplog` 默认关
- 不做 Sparkle；不做分析内删除 / 历史撤销
- Task 级 commit；默认 inline 执行
- 工作区若有无关 theme/sidebar 本地改动，**勿**并入本计划 commit

## File Map

| Path | Role |
|---|---|
| `vole-macos/Shell/ShellModule.swift` | 八模块枚举、标题、图标、顺序 |
| `vole-macos/Shell/ShellView.swift` | 路由 + sessions 注入；侧栏略加宽 |
| `vole-macos/Shell/SidebarView.swift` | 无需逻辑改（跟 `allCases`）；若标题截断可微调 padding |
| `vole-macos/Plan/PlanModuleKind.swift` | 增 `purge` / `installer` + 永久删除文案开关 |
| `vole-macos/Plan/PlanModuleSession.swift` | `permanentDelete`；apply 传 `--permanent` |
| `vole-macos/Plan/PlanModuleViews.swift` | 候选页永久删除 Toggle（仅 `supportsPermanent`） |
| `vole-macos/Analyze/AnalyzeSnapshot.swift` | `AnalyzeOutput` 解码 |
| `vole-macos/Analyze/AnalyzeSession.swift` | 栈钻取 / 扫 / 取消 / 选根 |
| `vole-macos/Analyze/AnalyzeRootView.swift` | 分析 UI |
| `vole-macos/History/HistorySnapshot.swift` | `history --json` 解码 |
| `vole-macos/History/HistorySession.swift` | 拉取 / limit / 刷新 |
| `vole-macos/History/HistoryRootView.swift` | 历史 UI |
| `vole-macos/Shell/SettingsToolsModel.swift` | Touch ID / 更新 / 自卸载编排 |
| `vole-macos/Shell/SettingsSheet.swift` | 三组 UI |
| `vole-macosTests/ShellViewTests.swift` | 八模块顺序与标题 |
| `vole-macosTests/PlanModuleSessionTests.swift` | purge/installer + permanent args |
| `vole-macosTests/AnalyzeSnapshotTests.swift` | JSON 解码 |
| `vole-macosTests/HistorySnapshotTests.swift` | JSON 解码 |
| `vole-macosTests/SettingsToolsModelTests.swift` | 命令参数拼装 |
| `README.md` | 功能面说明 |

---

### Task 1: ShellModule 八项 + 路由骨架

**Files:**
- Modify: `vole-macos/Shell/ShellModule.swift`
- Modify: `vole-macos/Shell/ShellView.swift`
- Modify: `vole-macosTests/ShellViewTests.swift`
- Create: `vole-macos/Shell/ModulePlaceholderView.swift`（临时；Task 3/4 删除或停用）

**Interfaces:**
- Produces: `ShellModule` cases `clean, uninstall, optimize, purge, installer, analyze, history, status`；`title` / `systemImage` / `isAvailable == true`
- Produces: `ShellView` switch 覆盖八项；新模块暂路由 `ModulePlaceholderView(title:)`
- Produces: `sidebarWidth` ≥ `148`

- [ ] **Step 1: 更新失败测试**

```swift
func test_allModulesAvailable() {
    XCTAssertEqual(
        ShellModule.allCases.map(\.isAvailable),
        Array(repeating: true, count: 8)
    )
    XCTAssertEqual(
        ShellModule.allCases.map(\.title),
        ["清理", "卸载", "优化", "净化", "安装包", "分析", "历史", "状态"]
    )
}

func test_moduleOrderStable() {
    XCTAssertEqual(
        ShellModule.allCases,
        [.clean, .uninstall, .optimize, .purge, .installer, .analyze, .history, .status]
    )
}
```

- [ ] **Step 2: 跑测试确认 RED**

```bash
xcodebuild test -scheme vole-macos -destination 'platform=macOS' \
  -only-testing:vole-macosTests/ShellViewTests
```

Expected: FAIL（仍为四模块）

- [ ] **Step 3: 实现 ShellModule + placeholder 路由**

`ShellModule.swift`：

```swift
enum ShellModule: String, CaseIterable, Identifiable {
    case clean, uninstall, optimize, purge, installer, analyze, history, status

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clean: return "清理"
        case .uninstall: return "卸载"
        case .optimize: return "优化"
        case .purge: return "净化"
        case .installer: return "安装包"
        case .analyze: return "分析"
        case .history: return "历史"
        case .status: return "状态"
        }
    }

    var isAvailable: Bool { true }

    var systemImage: String {
        switch self {
        case .clean: return "sparkles"
        case .uninstall: return "trash"
        case .optimize: return "gauge"
        case .purge: return "flame"
        case .installer: return "shippingbox"
        case .analyze: return "chart.pie"
        case .history: return "clock"
        case .status: return "chart.bar"
        }
    }
}
```

`ModulePlaceholderView.swift`：居中显示 `title` + 「加载中…」式短文案（Task 3/4 替换后删除文件）。

`ShellView`：`sidebarWidth = 148`；`detailView` switch 为新 case 路由 placeholder。

- [ ] **Step 4: 跑测试确认 GREEN**

同 Step 2。Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add vole-macos/Shell/ShellModule.swift \
  vole-macos/Shell/ShellView.swift \
  vole-macos/Shell/ModulePlaceholderView.swift \
  vole-macosTests/ShellViewTests.swift
git commit -m "$(cat <<'EOF'
feat: expand sidebar to eight CLI modules

Add purge/installer/analyze/history entries with placeholder detail
routes until each module lands.
EOF
)"
```

---

### Task 2: 净化 / 安装包 Plan 五态

**Files:**
- Modify: `vole-macos/Plan/PlanModuleKind.swift`
- Modify: `vole-macos/Plan/PlanModuleSession.swift`
- Modify: `vole-macos/Plan/PlanModuleViews.swift`（候选页 Toggle）
- Modify: `vole-macos/Shell/ShellView.swift`
- Modify: `vole-macosTests/PlanModuleSessionTests.swift`
- Delete or stop routing: placeholder for `.purge` / `.installer`

**Interfaces:**
- Consumes: 既有 `PlanModuleSession.startScan` / `applySelected` / `PrivilegedApply`
- Produces: `PlanModuleKind.purge` / `.installer`；`supportsPermanentDelete: Bool`；`permanentConfirmExtra: String`
- Produces: `PlanModuleSession.permanentDelete: Bool`（默认 `false`）；apply args 在为 true 时追加 `"--permanent"`
- Produces: `applyArguments(planPath:)` 纯函数或方法供测试断言（见下）

- [ ] **Step 1: 写失败测试**

```swift
func test_kindCommandsMatchCLI() {
    XCTAssertEqual(PlanModuleKind.uninstall.command, "uninstall")
    XCTAssertEqual(PlanModuleKind.optimize.command, "optimize")
    XCTAssertEqual(PlanModuleKind.purge.command, "purge")
    XCTAssertEqual(PlanModuleKind.installer.command, "installer")
    XCTAssertTrue(PlanModuleKind.purge.supportsPermanentDelete)
    XCTAssertTrue(PlanModuleKind.installer.supportsPermanentDelete)
    XCTAssertFalse(PlanModuleKind.uninstall.supportsPermanentDelete)
}

func test_applyArgumentsIncludePermanentWhenRequested() {
    let base = PlanModuleSession.applyArguments(
        command: "purge",
        planPath: "/tmp/p.json",
        permanent: true
    )
    XCTAssertEqual(base, ["purge", "--apply", "/tmp/p.json", "--json-stream", "--permanent"])
    let off = PlanModuleSession.applyArguments(
        command: "installer",
        planPath: "/tmp/i.json",
        permanent: false
    )
    XCTAssertEqual(off, ["installer", "--apply", "/tmp/i.json", "--json-stream"])
}

func test_copyLocalized() {
    XCTAssertEqual(PlanModuleKind.purge.title, "净化")
    XCTAssertEqual(PlanModuleKind.installer.title, "安装包")
    XCTAssertEqual(PlanModuleKind.purge.primaryActionTitle, "净化所选")
    XCTAssertEqual(PlanModuleKind.installer.primaryActionTitle, "清理所选")
}
```

- [ ] **Step 2: RED**

```bash
xcodebuild test -scheme vole-macos -destination 'platform=macOS' \
  -only-testing:vole-macosTests/PlanModuleSessionTests
```

Expected: FAIL（无 purge/installer / `applyArguments`）

- [ ] **Step 3: 实现 Kind + Session + UI 接线**

在 `PlanModuleKind` 为每个 case 补齐与 uninstall/optimize 同形的中文字段，例如：

| kind | idleHeadline | candidatesTitle | primaryActionTitle | confirmButton |
|---|---|---|---|---|
| purge | 挖出陈旧构建物 | 挑要净化的 | 净化所选 | 确认净化 |
| installer | 找出安装包 | 挑要清理的 | 清理所选 | 确认清理 |

`supportsPermanentDelete`：仅 `purge` / `installer` 为 `true`。  
确认文案在 `permanentDelete == true` 时追加「将永久删除，不可从废纸篓恢复」。

`PlanModuleSession`：

```swift
@Published var permanentDelete: Bool = false

static func applyArguments(command: String, planPath: String, permanent: Bool) -> [String] {
    var args = [command, "--apply", planPath, "--json-stream"]
    if permanent { args.append("--permanent") }
    return args
}
```

将现有 apply 里硬编码的 arguments 数组改为调用 `applyArguments(command:kind.command, planPath:applyURL.path, permanent: permanentDelete && kind.supportsPermanentDelete)`。

`PlanModuleCandidatesView`：若 `session.kind.supportsPermanentDelete`，在动作条上方加：

```swift
Toggle("永久删除（不进废纸篓）", isOn: $session.permanentDelete)
```

`ShellView`：

```swift
@StateObject private var purgeSession = PlanModuleSession(kind: .purge)
@StateObject private var installerSession = PlanModuleSession(kind: .installer)
// switch:
case .purge:
    PlanModuleRootView(session: purgeSession, helperStatus: helperStatus)
case .installer:
    PlanModuleRootView(session: installerSession, helperStatus: helperStatus)
```

- [ ] **Step 4: GREEN** — 同 Step 2，Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add vole-macos/Plan/PlanModuleKind.swift \
  vole-macos/Plan/PlanModuleSession.swift \
  vole-macos/Plan/PlanModuleViews.swift \
  vole-macos/Shell/ShellView.swift \
  vole-macosTests/PlanModuleSessionTests.swift
git commit -m "$(cat <<'EOF'
feat: add purge and installer plan modules

Reuse PlanModuleSession with optional --permanent for trash bypass.
EOF
)"
```

---

### Task 3: 分析模块（钻取对齐 CLI TUI）

**Files:**
- Create: `vole-macos/Analyze/AnalyzeSnapshot.swift`
- Create: `vole-macos/Analyze/AnalyzeSession.swift`
- Create: `vole-macos/Analyze/AnalyzeRootView.swift`
- Create: `vole-macosTests/AnalyzeSnapshotTests.swift`
- Modify: `vole-macos/Shell/ShellView.swift`
- Delete: placeholder 路由（若仅分析/历史仍用，可留到 Task 4 删）

**Interfaces:**
- Consumes: `VoleProcess.run(arguments: ["analyze", "--json", path], …)`
- Produces:
  - `struct AnalyzeSnapshot: Codable, Equatable`（`path`, `overview`, `entries`, `largeFiles`, `totalSize`, `totalFiles`）
  - `struct AnalyzeEntryItem` / `AnalyzeFileItem`（字段对齐 CLI snake_case）
  - `AnalyzeSession`: `@Published pathStack: [String]`，`entries`，`largeFiles`，`totalSize`，`totalFiles`，`isScanning`，`errorMessage`，`selectedPath`
  - `func scanRoot(_ path: String)` / `func enterDirectory(_ path: String)` / `func goUp()` / `func cancel()` / `func chooseFolder()`（`NSOpenPanel`）

- [ ] **Step 1: 解码测试（fixture）**

```swift
func test_decodeAnalyzeOutput() throws {
    let json = """
    {"path":"/tmp","overview":false,"entries":[{"name":"a","path":"/tmp/a","size":10,"is_dir":true}],"large_files":[{"name":"b","path":"/tmp/b","size":99}],"total_size":100,"total_files":2}
    """
    let snap = try AnalyzeSnapshot.decode(fromJSONLine: json)
    XCTAssertEqual(snap.path, "/tmp")
    XCTAssertEqual(snap.entries.count, 1)
    XCTAssertEqual(snap.entries[0].name, "a")
    XCTAssertTrue(snap.entries[0].isDir)
    XCTAssertEqual(snap.largeFiles.first?.size, 99)
    XCTAssertEqual(snap.totalSize, 100)
    XCTAssertEqual(snap.totalFiles, 2)
}
```

- [ ] **Step 2: RED**

```bash
xcodebuild test -scheme vole-macos -destination 'platform=macOS' \
  -only-testing:vole-macosTests/AnalyzeSnapshotTests
```

Expected: FAIL（类型不存在）

- [ ] **Step 3: 实现 Snapshot + Session + UI**

解码：`JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase`（同 `StatusSnapshot`）。

`AnalyzeSession` 行为：

1. `init`：`pathStack = [NSHomeDirectory()]`，自动 `rescan()`
2. `rescan()`：对 `pathStack.last` 跑 `analyze --json <path>`；扫描中 `isScanning=true`；成功写入 entries / largeFiles / totals；失败写 `errorMessage`
3. `enterDirectory`：仅当 `isDir`；`pathStack.append`；`rescan()`
4. `goUp()`：`pathStack.count > 1` 时 `removeLast` + `rescan()`
5. `cancel()`：`process.cancel()`
6. `chooseFolder()`：`NSOpenPanel`（directories only）→ 重置 stack 为所选路径 → `rescan()`

`AnalyzeRootView`：

- 顶栏：当前 path（monospace 截断）+「选择文件夹」+（可返回时）「上一级」
- 扫描中：SoilPanel / 进度文案 +「取消」
- 列表：`ForEach(entries)` — 目录行可点 `enterDirectory`；显示 `ByteFormat` 体积
- 底部：`Large files` 区（最多展示 sidecar 返回项，UI 取前 8）
- 错误：橙色 caption

`ShellView`：`@StateObject private var analyzeSession = AnalyzeSession()`；`case .analyze: AnalyzeRootView(session: analyzeSession)`

- [ ] **Step 4: GREEN** — 同 Step 2

- [ ] **Step 5: Commit**

```bash
git add vole-macos/Analyze vole-macosTests/AnalyzeSnapshotTests.swift \
  vole-macos/Shell/ShellView.swift
git commit -m "$(cat <<'EOF'
feat: add analyze module with directory drill-down

Drive analyze --json from the sidebar with stack navigation and folder picker.
EOF
)"
```

---

### Task 4: 历史模块

**Files:**
- Create: `vole-macos/History/HistorySnapshot.swift`
- Create: `vole-macos/History/HistorySession.swift`
- Create: `vole-macos/History/HistoryRootView.swift`
- Create: `vole-macosTests/HistorySnapshotTests.swift`
- Modify: `vole-macos/Shell/ShellView.swift`
- Delete: `vole-macos/Shell/ModulePlaceholderView.swift`（若已无引用）

**Interfaces:**
- Consumes: `VoleProcess.run(arguments: ["history", "--json", "--limit", "\(limit)"], …)`
- Produces: `HistorySnapshot`（`logs`, `limit`, `sessions`, `deletions`）；`HistorySession.refresh()`；`limit` 夹在 `1...200`，默认 `20`

- [ ] **Step 1: 解码测试**

```swift
func test_decodeHistoryJSON() throws {
    let json = """
    {"logs":{"operations":"/tmp/ops.log","deletions":"/tmp/del.log"},"limit":2,"sessions":[{"command":"optimize","started_at":"2026-08-09 06:32:24","ended_at":"2026-08-09 06:32:46","items":10,"size":"0B","operation_count":0,"actions":{"removed":0,"trashed":0,"skipped":0,"failed":0,"rebuilt":0,"other":0}}],"deletions":[{"timestamp":"2026-08-08T14:31:31+0000","mode":"trash","status":"ok","size_kb":4,"path":"/tmp/x"}]}
    """
    let snap = try HistorySnapshot.decode(fromJSONLine: json)
    XCTAssertEqual(snap.limit, 2)
    XCTAssertEqual(snap.sessions.first?.command, "optimize")
    XCTAssertEqual(snap.deletions.first?.path, "/tmp/x")
    XCTAssertEqual(snap.deletions.first?.sizeKb, 4)
}
```

- [ ] **Step 2: RED** — `HistorySnapshotTests`

- [ ] **Step 3: 实现**

`HistorySession`：`@Published var limit: UInt = 20`；`refresh()` 调 sidecar；空 sessions+deletions 显示空态「暂无操作记录」。

`HistoryRootView`：

- 顶栏：标题「操作历史」+ Stepper/字段调 limit +「刷新」
- Section「会话」：command、起止时间、items、size、actions 摘要
- Section「删除审计」：timestamp、mode、status、size、path（monospace 截断）

接线 `ShellView` `case .history`。删除 `ModulePlaceholderView`。

- [ ] **Step 4: GREEN**

- [ ] **Step 5: Commit**

```bash
git add vole-macos/History vole-macosTests/HistorySnapshotTests.swift \
  vole-macos/Shell/ShellView.swift
git rm -f vole-macos/Shell/ModulePlaceholderView.swift 2>/dev/null || true
git commit -m "$(cat <<'EOF'
feat: add history module from history --json

Show sessions and deletion audit with adjustable limit.
EOF
)"
```

---

### Task 5: 设置 — Touch ID / 更新 / 自卸载

**Files:**
- Create: `vole-macos/Shell/SettingsToolsModel.swift`
- Create: `vole-macosTests/SettingsToolsModelTests.swift`
- Modify: `vole-macos/Shell/SettingsSheet.swift`
- Modify: `vole-macos/Shell/ShellView.swift`（注入 model 如需要）

**Interfaces:**
- Produces: `SettingsToolsModel`（`@MainActor ObservableObject`）
  - Touch ID: `touchIdConfigured: Bool?`，`touchIdMessage`，`refreshTouchId()`，`enableTouchId()`，`disableTouchId()`
  - Update: `updateCheckText` / `UpdateCheckResult?`，`checkForUpdate()`，`runUpdate(force:nightly:)`
  - Remove: `removePreviewItems: [RemovePreviewItem]`，`purgeOplog: Bool`（默认 false），`previewRemove()`，`confirmRemove()`
- Produces: 静态命令拼装供测：
  - `touchIdArgs(action:)` → `["touchid", action, "--json"]`
  - `updateCheckArgs()` → `["update", "--check", "--json"]`
  - `updateApplyArgs(force:nightly:)` → 含 `--yes --json` 及可选 flag
  - `removeDryRunArgs(purgeOplog:)` / `removeApplyArgs(purgeOplog:)`

JSON 形状（CLI 实测）：

```json
// touchid status
{"configured":false,"pam_tid_line":"auth       sufficient     pam_tid.so","uses_sudo_local":true}

// update --check
{"channel":"stable","current":"2.5.0","latest":"2.5.0","origin":"manual","outcome":"check"}

// remove --dry-run
{"homebrew":false,"items":[{"kind":"manual_binary","note":null,"path":"/…/vole"}],"status":"dry_run"}
```

- [ ] **Step 1: 命令拼装测试**

```swift
func test_settingsToolArguments() {
    XCTAssertEqual(
        SettingsToolsModel.touchIdArgs(action: "status"),
        ["touchid", "status", "--json"]
    )
    XCTAssertEqual(
        SettingsToolsModel.updateCheckArgs(),
        ["update", "--check", "--json"]
    )
    XCTAssertEqual(
        SettingsToolsModel.updateApplyArgs(force: false, nightly: false),
        ["update", "--yes", "--json"]
    )
    XCTAssertEqual(
        SettingsToolsModel.removeDryRunArgs(purgeOplog: false),
        ["remove", "--dry-run", "--json"]
    )
    XCTAssertEqual(
        SettingsToolsModel.removeApplyArgs(purgeOplog: true),
        ["remove", "--yes", "--json", "--purge-oplog"]
    )
}
```

- [ ] **Step 2: RED**

- [ ] **Step 3: 实现 Model + Settings UI**

`SettingsToolsModel`：各操作经 `VoleProcess`；解码失败或非零退出写入对应 `errorMessage`。  
`SettingsSheet` 在「关于」前插入三组：

1. **Touch ID**：状态文案（已配置/未配置）+ 刷新 + 启用 + 禁用  
2. **更新**：检查结果（current / latest / origin）+「检查更新」+「安装更新」（确认 `confirmationDialog`）  
3. **自卸载**：dry-run 列表 + `Toggle("同时删除审计日志")`（默认关）+「预览」+「确认自卸载」（二次确认；执行后可提示 App 可能需退出）

`ShellView` sheet：

```swift
SettingsSheet(
    helperStatus: helperStatus,
    voleVersion: session.voleVersion,
    onRefreshVersion: { session.refreshVersion() },
    tools: toolsModel
)
```

- [ ] **Step 4: GREEN**

- [ ] **Step 5: Commit**

```bash
git add vole-macos/Shell/SettingsToolsModel.swift \
  vole-macos/Shell/SettingsSheet.swift \
  vole-macos/Shell/ShellView.swift \
  vole-macosTests/SettingsToolsModelTests.swift
git commit -m "$(cat <<'EOF'
feat: add Touch ID, update, and remove in settings

Wire settings tools to sidecar JSON for status, check, and dry-run flows.
EOF
)"
```

---

### Task 6: README + 全量测试

**Files:**
- Modify: `README.md`
- （无新代码除非修编译告警）

- [ ] **Step 1: 更新 README 功能面**

将开篇与「特权助手」小节中的侧栏描述改为八模块；设置补充 Touch ID / 更新 / 自卸载；链到本 design：

`docs/wukong-code/specs/2026-08-09-1454-app-nav-cli-parity-design.md`

- [ ] **Step 2: 全量测试**

```bash
xcodebuild test -scheme vole-macos -destination 'platform=macOS'
```

Expected: 全部 PASS

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "$(cat <<'EOF'
docs: document eight-module sidebar and settings tools
EOF
)"
```

---

## Spec coverage (self-review)

| Spec § | Task |
|---|---|
| §3 侧栏八项顺序 / 图标 / 路由 | T1, T2–T4 |
| §4 净化/安装包 + permanent 默认关 | T2 |
| §5 分析钻取 / 选文件夹 / 取消 / 大文件 | T3 |
| §6 历史 sessions + deletions + limit | T4 |
| §7 Touch ID / 更新 / 自卸载 | T5 |
| §8 不做项 | 全任务约束；无 Sparkle / 无分析删除 |
| §10 验收 / 单测 | 各 Task 测试 + T6 全量 |

## Placeholder / 类型一致性

- 无 TBD；`applyArguments` / `SettingsToolsModel.*Args` 名称在测试与实现间一致
- `AnalyzeSnapshot.largeFiles` / `HistorySnapshot` 的 `sizeKb` 与 `convertFromSnakeCase` 对齐 `size_kb`
- Task 1 placeholder 在 Task 4 删除
