# Desktop Worktree + Agent Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use wukong-code:subagent-driven-development (recommended) or wukong-code:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 vole-macos 主侧栏插入 Worktree 与 Agent，复用现有 Plan 五态消费内嵌 `vole` 2.20.0 的 `worktree` / `agent` plan→勾选→apply，无 sidecar 2.20.x 时两项不可用。

**Architecture:** 不新做专用页、不嵌 TUI。扩 `PlanModuleKind` 与 `PlanModuleSession`；`ShellView` 再挂两个 `PlanModuleSession` 并路由到既有 `PlanModuleRootView`。运行时用 `SidecarVersion` 解析 sidecar `--version`，注入 `ShellModule.isAvailable(sidecarVersion:)`。删除只走 sidecar `--apply` + 既有 `PrivilegedApply` / Helper，不新开 SMAppService，不在 App 里对用户勾选项 `FileManager` 直删。

**Tech Stack:** SwiftUI、XCTest（与 `ShellViewTests` / `PlanModuleSessionTests` 同风）、Swift Testing（与 `SidecarRunnerTests` 同风）、既有 `VoleProcess` / `PlanIO` / `PrivilegedApply` / `VoleTheme`、`scripts/embed-vole.sh`、GitHub Actions `release.yml`。

## Global Constraints

- 内嵌 sidecar **恰好 `vole` 2.20.0**（与已发 CLI tag `v2.20.0` 对齐；`--version` 必须解析为 `2.20.0`，不得把未发布的更新 CLI 带进窗口包）
- 不 bump `schema_version`（`PlanIO.expectedSchemaVersion` 保持 `1`）
- 无第二条删除路径（App 不得对用户勾选项走 `FileManager` 直删；只走 sidecar apply + 既有 Helper 分区）
- Plan 五态：空闲 → 扫描 → 候选 → 确认 → 结果（复用 `PlanModuleSession.Phase`：`idle` / `scanning` / `candidates` / `applying` / `result`）
- 默认全不选（`worktree` / `agent` 进入候选页 0 条预勾选；既有 uninstall / optimize / purge / installer 仍默认全选）
- 默认废纸篓；永久删除开关默认关（`PlanModuleSession.permanentDelete` 保持 `false`）
- 侧栏顺序：清理 → 卸载 → 优化 → 净化 → 安装包 → **Worktree → Agent** → 分析 → 历史 → 状态
- 本计划不发 vole-macos 版（不打 tag、不建 GitHub Release、不改 `MARKETING_VERSION` 0.2.0）
- 兄弟仓 `vole` CLI **零改**（只读契约：`worktree|agent --plan --json-stream --plan-out` / `--apply <plan> --json-stream` / 可选 `--permanent`）

## File Map

| Path | Role |
|---|---|
| `vole-macos/Sidecar/SidecarVersion.swift` | 解析 `--version` 首行第一个 `X.Y.Z`；`supportsWorktreeAgent` |
| `vole-macosTests/SidecarVersionTests.swift` | 版本解析与 2.20.x 门控（Swift Testing，对齐 `SidecarRunnerTests`） |
| `scripts/embed-vole.sh` | 嵌入后跑 `vole-cli --version`，不是恰好 `2.20.0` 则失败 |
| `.github/workflows/release.yml` | checkout 兄弟仓钉 `ref: v2.20.0` |
| `vole-macos/Plan/PlanModuleKind.swift` | 增 `worktree` / `agent`；`selectsAllCandidatesByDefault`；规格文案 |
| `vole-macos/Plan/PlanModuleSession.swift` | 按 kind 决定扫完勾选；扫描参数抽出可测函数 |
| `vole-macos/Shell/ShellModule.swift` | 十项 `CaseIterable`；`isAvailable(sidecarVersion:)` |
| `vole-macos/Shell/SidebarView.swift` | 注入 sidecar 版本；不可用帮助不是「即将推出」 |
| `vole-macos/Shell/ShellView.swift` | 两套 session、路由、侧栏宽度、mascot 六路 plan |
| `vole-macos/Plan/PlanModuleViews.swift` | 空闲「开始扫描」在版本门控失败时不调 sidecar |
| `vole-macosTests/ShellViewTests.swift` | 十项顺序 / 标题 / 可用性（XCTest） |
| `vole-macosTests/PlanModuleSessionTests.swift` | kind / 默认勾选 / apply 参数 / 风险文案（XCTest） |
| `README.md` 等五语 | 能力表加 Worktree / Agent；不写「已随 0.2.0 发布」 |
| `images/` | 实现后截图（最后一任务） |

新 Swift 文件落在 `PBXFileSystemSynchronizedRootGroup`（`vole-macos/`、`vole-macosTests/`），**不必改** `vole-macos.xcodeproj/project.pbxproj`。

### 现状锚点（实现前不要猜）

- `ShellModule` 八项、`isAvailable` 无参恒 `true`：`vole-macos/Shell/ShellModule.swift`
- 侧栏 `help` 在不可用时写「即将推出」：`vole-macos/Shell/SidebarView.swift` 第 113 行
- `sidebarWidth = 148`、四套 Plan session：`vole-macos/Shell/ShellView.swift`
- `PlanModuleKind` 四 case；无 `selectsAllCandidatesByDefault`：`vole-macos/Plan/PlanModuleKind.swift`
- 扫完 `selectedIDs = Set(entries.map(\.id))`：`PlanModuleSession.handlePlanExit` 第 258 行
- apply：`[command, "--apply", planPath, "--json-stream"]` + 可选 `--permanent`：`PlanModuleSession.applyArguments`
- 扫描：`[kind.command, "--plan", "--json-stream", "--plan-out", planURL.path]`：`startScan` 第 78–80 行
- 用户域删除只经 sidecar；系统路径经 `PrivilegedApply.applyPrivilegedPaths` → `HelperXPCClient`。`FileManager.removeItem` 仅删本地 plan 缓存 JSON（`applyURL` / `fullPlanURL`），不是第二条用户删除路径
- clap `name = "vole"`，`--version` 形如 `vole 2.20.0`；嵌入二进制名为 `Contents/MacOS/vole-cli`
- 兄弟仓 tag `v2.20.0` 的 workspace `version = "2.20.0"`；CLI 锁错误：`another vole worktree is running` / `another vole agent is running`

### CLI 契约（只读，不改 vole 仓）

`crates/vole-cli/src/main.rs` 中 `Worktree` / `Agent` 与 purge 同形：

- 扫描：`worktree|agent --plan --json-stream --plan-out <path>`
- 应用：`worktree|agent --apply <plan> --json-stream`；永久删除再追加 `--permanent`
- 互斥：CLI 内 `try_lock_worktree` / `try_lock_agent`（各锁各的）。UI 只展示 `SidecarExit.failed` 真错误

---

### Task 1: Sidecar 钉 2.20.0 + 版本解析门控

**Files:**
- Create: `vole-macos/Sidecar/SidecarVersion.swift`
- Create: `vole-macosTests/SidecarVersionTests.swift`
- Modify: `scripts/embed-vole.sh`（在 `sign_sidecar` 成功之后、rules rsync 之前插入版本门）
- Modify: `.github/workflows/release.yml`（Checkout vole 一步加 `ref: v2.20.0`）

**Interfaces:**
- Consumes: sidecar `--version` 文本（首行）；嵌入二进制 `$MACOS_DIR/vole-cli`
- Produces: `enum SidecarVersion` 含 `static func parse(_ raw: String) -> (major: Int, minor: Int, patch: Int)?` 与 `static func supportsWorktreeAgent(_ raw: String) -> Bool`
- Produces: `static let requiredExactEmbedded = "2.20.0"`（仅 embed 脚本语义；Swift 运行时门控是 **主.次 = 2.20**）
- Produces: CI 构建源钉 Git tag `v2.20.0`；不改 `PlanIO.expectedSchemaVersion`

- [ ] **Step 1: Write the failing test**

创建 `vole-macosTests/SidecarVersionTests.swift`（Swift Testing，对齐 `SidecarRunnerTests`）：

```swift
import Foundation
import Testing
@testable import vole_macos

struct SidecarVersionTests {
    @Test func parsesVolePrefix() {
        let v = SidecarVersion.parse("vole 2.20.0")
        #expect(v?.major == 2)
        #expect(v?.minor == 20)
        #expect(v?.patch == 0)
    }

    @Test func parsesVoleCliPrefix() {
        let v = SidecarVersion.parse("vole-cli 2.20.0")
        #expect(v?.major == 2)
        #expect(v?.minor == 20)
        #expect(v?.patch == 0)
    }

    @Test func usesFirstSemVerOnFirstLine() {
        let raw = "vole 2.20.1 (rev abc)\nextra 9.9.9"
        let v = SidecarVersion.parse(raw)
        #expect(v?.major == 2)
        #expect(v?.minor == 20)
        #expect(v?.patch == 1)
    }

    @Test func prereleaseStillUsesMajorMinor() {
        #expect(SidecarVersion.supportsWorktreeAgent("vole 2.20.0-beta.1"))
        #expect(SidecarVersion.supportsWorktreeAgent("vole 2.20.3"))
    }

    @Test func rejectsNon220AndGarbage() {
        #expect(!SidecarVersion.supportsWorktreeAgent("vole 2.19.9"))
        #expect(!SidecarVersion.supportsWorktreeAgent("vole 2.21.0"))
        #expect(!SidecarVersion.supportsWorktreeAgent("vole"))
        #expect(!SidecarVersion.supportsWorktreeAgent(""))
        #expect(SidecarVersion.parse("no version here") == nil)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
xcodebuild test -scheme vole-macos -destination 'platform=macOS' \
  -only-testing:vole-macosTests/SidecarVersionTests
```

Expected: FAIL（`SidecarVersion` 未定义）

- [ ] **Step 3: Write minimal implementation**

`vole-macos/Sidecar/SidecarVersion.swift`：

```swift
import Foundation

enum SidecarVersion {
    static let requiredExactEmbedded = "2.20.0"

    static func parse(_ raw: String) -> (major: Int, minor: Int, patch: Int)? {
        let firstLine = raw.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
            .first
            .map(String.init) ?? ""
        guard let regex = try? NSRegularExpression(pattern: #"(\d+)\.(\d+)\.(\d+)"#) else {
            return nil
        }
        let ns = firstLine as NSString
        let range = NSRange(location: 0, length: ns.length)
        guard let match = regex.firstMatch(in: firstLine, range: range),
              match.numberOfRanges >= 4,
              let major = Int(ns.substring(with: match.range(at: 1))),
              let minor = Int(ns.substring(with: match.range(at: 2))),
              let patch = Int(ns.substring(with: match.range(at: 3)))
        else {
            return nil
        }
        return (major, minor, patch)
    }

    static func supportsWorktreeAgent(_ raw: String) -> Bool {
        guard let v = parse(raw) else { return false }
        return v.major == 2 && v.minor == 20
    }
}
```

`scripts/embed-vole.sh`：在 `sign_sidecar "$MACOS_DIR/$SIDECAR_NAME"` 之后插入（不要 `git checkout` 兄弟仓，以免改 CLI 工作区）：

```bash
REQUIRED_SIDECAR_VERSION="2.20.0"
ver_line="$("$MACOS_DIR/$SIDECAR_NAME" --version 2>/dev/null | head -n 1 || true)"
if [[ ! "$ver_line" =~ ([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
  echo "error: could not parse sidecar --version from: ${ver_line:-<empty>}" >&2
  echo "hint: VOLE_SRC must be vole 2.20.0 (tag v2.20.0). Do not embed unpublished CLI." >&2
  exit 1
fi
got_ver="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}.${BASH_REMATCH[3]}"
if [[ "$got_ver" != "$REQUIRED_SIDECAR_VERSION" ]]; then
  echo "error: embedded sidecar must be exactly vole ${REQUIRED_SIDECAR_VERSION}, got: $ver_line" >&2
  echo "hint: point VOLE_SRC at wukongnotnull/vole @ v2.20.0 (do not edit the CLI repo in this milestone)" >&2
  exit 1
fi
echo "note: sidecar --version OK ($ver_line)"
```

`.github/workflows/release.yml` 的 Checkout vole 步改为：

```yaml
      - name: Checkout vole (sidecar source)
        uses: actions/checkout@v4
        with:
          repository: wukongnotnull/vole
          path: vole
          ref: v2.20.0
```

不要改 `PlanIO.expectedSchemaVersion`。不要 bump `MARKETING_VERSION`。

- [ ] **Step 4: Run test to verify it passes**

```bash
xcodebuild test -scheme vole-macos -destination 'platform=macOS' \
  -only-testing:vole-macosTests/SidecarVersionTests
bash -n scripts/embed-vole.sh
```

Expected: SidecarVersionTests PASS；`bash -n` 无输出、退出 0。

本机若 `VOLE_SRC` 已是 2.20.0，可再跑一次 Debug embed 确认门通过。若兄弟仓 checkout 不是 2.20.0，embed **必须**失败——这是门控，不要放宽成 2.20.x。

- [ ] **Step 5: Commit**

```bash
git add vole-macos/Sidecar/SidecarVersion.swift \
  vole-macosTests/SidecarVersionTests.swift \
  scripts/embed-vole.sh \
  .github/workflows/release.yml
git commit -m "$(cat <<'EOF'
build: pin embedded vole sidecar to 2.20.0

Fail embed and release checkout unless the sidecar is exactly 2.20.0,
and parse --version for the desktop 2.20.x feature gate.
EOF
)"
```

---

### Task 2: 扩展 PlanModuleKind（worktree + agent）

**Files:**
- Modify: `vole-macos/Plan/PlanModuleKind.swift`
- Modify: `vole-macosTests/PlanModuleSessionTests.swift`

**Interfaces:**
- Consumes: 既有 `PlanModuleKind` 四 case 的字段形状（`command`、`supportsPermanentDelete`、`title`、idle/scan/candidates/apply/confirm/result 文案、`planFilePrefix` / `applyFilePrefix`）
- Produces: `PlanModuleKind.worktree` / `.agent`（`CaseIterable` 顺序：`uninstall, optimize, purge, installer, worktree, agent`）
- Produces: `var command: String` → `"worktree"` / `"agent"`（仍 `rawValue`）
- Produces: `var supportsPermanentDelete: Bool` → worktree/agent 为 `true`（与 purge/installer 同）
- Produces: `var selectsAllCandidatesByDefault: Bool` → uninstall/optimize/purge/installer 为 `true`；worktree/agent 为 `false`
- Produces: 规格 §4.5 全部中文键（见 Step 3 完整 switch）

- [ ] **Step 1: Write the failing test**

在 `PlanModuleSessionTests` 追加（XCTest，对齐现有文件）：

```swift
    func test_worktreeAgentKindFlags() {
        XCTAssertEqual(PlanModuleKind.worktree.command, "worktree")
        XCTAssertEqual(PlanModuleKind.agent.command, "agent")
        XCTAssertEqual(PlanModuleKind.worktree.planFilePrefix, "worktree-full")
        XCTAssertEqual(PlanModuleKind.agent.applyFilePrefix, "agent-apply")
        XCTAssertTrue(PlanModuleKind.worktree.supportsPermanentDelete)
        XCTAssertTrue(PlanModuleKind.agent.supportsPermanentDelete)
        XCTAssertTrue(PlanModuleKind.purge.selectsAllCandidatesByDefault)
        XCTAssertTrue(PlanModuleKind.installer.selectsAllCandidatesByDefault)
        XCTAssertTrue(PlanModuleKind.uninstall.selectsAllCandidatesByDefault)
        XCTAssertTrue(PlanModuleKind.optimize.selectsAllCandidatesByDefault)
        XCTAssertFalse(PlanModuleKind.worktree.selectsAllCandidatesByDefault)
        XCTAssertFalse(PlanModuleKind.agent.selectsAllCandidatesByDefault)
    }

    func test_worktreeAgentCopyRiskPhrases() {
        XCTAssertEqual(PlanModuleKind.worktree.title, "Worktree")
        XCTAssertEqual(PlanModuleKind.agent.title, "Agent")
        XCTAssertEqual(PlanModuleKind.worktree.idleEyebrow, "Worktree · 工作树")
        XCTAssertEqual(PlanModuleKind.agent.idleEyebrow, "Agent · 代理残留")
        XCTAssertEqual(PlanModuleKind.worktree.idleHeadline, "翻出被遗忘的 checkout")
        XCTAssertEqual(PlanModuleKind.agent.idleHeadline, "翻出 Agent 留下的容器")
        XCTAssertTrue(PlanModuleKind.worktree.idleCaption.contains("不宣称可安全删除"))
        XCTAssertTrue(PlanModuleKind.agent.idleCaption.contains("不宣称可安全删除"))
        XCTAssertFalse(PlanModuleKind.worktree.idleCaption.contains("可安全删除"))
        XCTAssertFalse(PlanModuleKind.agent.idleCaption.contains("放心删"))
        XCTAssertEqual(PlanModuleKind.worktree.candidatesTitle, "挑要移走的 checkout")
        XCTAssertEqual(PlanModuleKind.agent.candidatesTitle, "挑要移走的残留")
        XCTAssertEqual(PlanModuleKind.worktree.primaryActionTitle, "清理所选")
        XCTAssertEqual(PlanModuleKind.agent.primaryActionTitle, "清理所选")
        XCTAssertEqual(PlanModuleKind.worktree.confirmButton, "确认清理")
        XCTAssertEqual(PlanModuleKind.agent.confirmButton, "确认清理")
        XCTAssertEqual(PlanModuleKind.worktree.resultTitle, "Worktree 清理完成")
        XCTAssertEqual(PlanModuleKind.agent.resultTitle, "Agent 清理完成")

        let wt = PlanModuleKind.worktree.confirmTitle(permanentDelete: false)
        let ag = PlanModuleKind.agent.confirmTitle(permanentDelete: false)
        XCTAssertTrue(wt.contains("不宣称可安全删除"))
        XCTAssertTrue(ag.contains("不宣称可安全删除"))
        XCTAssertTrue(wt.contains("废纸篓"))
        XCTAssertTrue(ag.contains("废纸篓"))
        XCTAssertTrue(wt.contains("整棵 Git checkout"))
        XCTAssertTrue(ag.contains("容器"))
        XCTAssertFalse(ag.contains("Git checkout") && ag.contains("将删除已选的整棵"))

        let wtPerm = PlanModuleKind.worktree.confirmTitle(permanentDelete: true)
        let agPerm = PlanModuleKind.agent.confirmTitle(permanentDelete: true)
        XCTAssertTrue(wtPerm.contains("将永久删除，不可从废纸篓恢复"))
        XCTAssertTrue(agPerm.contains("将永久删除，不可从废纸篓恢复"))
    }
```

保留并扩展既有 `test_kindCommandsMatchCLI`：在文件末尾断言处不要删除 purge/installer 覆盖。新测试单独成方法即可。

- [ ] **Step 2: Run test to verify it fails**

```bash
xcodebuild test -scheme vole-macos -destination 'platform=macOS' \
  -only-testing:vole-macosTests/PlanModuleSessionTests
```

Expected: FAIL（无 `worktree` / `agent` case，无 `selectsAllCandidatesByDefault`）

- [ ] **Step 3: Write minimal implementation**

`PlanModuleKind.swift` 全文替换为：

```swift
import Foundation

enum PlanModuleKind: String, CaseIterable, Identifiable {
    case uninstall
    case optimize
    case purge
    case installer
    case worktree
    case agent

    var id: String { rawValue }

    var command: String { rawValue }

    var supportsPermanentDelete: Bool {
        switch self {
        case .purge, .installer, .worktree, .agent: return true
        case .uninstall, .optimize: return false
        }
    }

    var selectsAllCandidatesByDefault: Bool {
        switch self {
        case .uninstall, .optimize, .purge, .installer: return true
        case .worktree, .agent: return false
        }
    }

    var title: String {
        switch self {
        case .uninstall: return "卸载"
        case .optimize: return "优化"
        case .purge: return "净化"
        case .installer: return "安装包"
        case .worktree: return "Worktree"
        case .agent: return "Agent"
        }
    }

    var idleEyebrow: String {
        switch self {
        case .uninstall: return "Uninstall · 卸载"
        case .optimize: return "Optimize · 优化"
        case .purge: return "Purge · 净化"
        case .installer: return "Installer · 安装包"
        case .worktree: return "Worktree · 工作树"
        case .agent: return "Agent · 代理残留"
        }
    }

    var idleHeadline: String {
        switch self {
        case .uninstall: return "挖出残留应用"
        case .optimize: return "松土优化系统"
        case .purge: return "挖出陈旧构建物"
        case .installer: return "找出安装包"
        case .worktree: return "翻出被遗忘的 checkout"
        case .agent: return "翻出 Agent 留下的容器"
        }
    }

    var idleCaption: String {
        switch self {
        case .uninstall: return "扫描可卸载应用与用户域残留"
        case .optimize: return "扫描可执行的优化任务"
        case .purge: return "扫描陈旧项目构建物"
        case .installer: return "扫描可清理的安装包"
        case .worktree:
            return "扫描遗留的 Git worktree。将整棵 checkout 送进废纸篓。不宣称可安全删除。"
        case .agent:
            return "扫描 Agent 容器、会话与缓存残留（不是 Git checkout）。默认进废纸篓。不宣称可安全删除。"
        }
    }

    var scanEyebrow: String { "Scanning · 扫描中" }
    var scanTitle: String { "正在翻找" }

    var candidatesEyebrow: String { "Candidates · 候选" }
    var candidatesTitle: String {
        switch self {
        case .uninstall: return "挑要卸载的"
        case .optimize: return "挑要执行的"
        case .purge: return "挑要净化的"
        case .installer: return "挑要清理的"
        case .worktree: return "挑要移走的 checkout"
        case .agent: return "挑要移走的残留"
        }
    }

    var applyEyebrow: String {
        switch self {
        case .uninstall: return "Applying · 卸载中"
        case .optimize: return "Applying · 优化中"
        case .purge: return "Applying · 净化中"
        case .installer: return "Applying · 清理中"
        case .worktree: return "Applying · 清理中"
        case .agent: return "Applying · 清理中"
        }
    }

    var applyTitle: String {
        switch self {
        case .uninstall: return "正在卸载"
        case .optimize: return "正在优化"
        case .purge: return "正在净化"
        case .installer: return "正在清理安装包"
        case .worktree: return "正在移走 checkout"
        case .agent: return "正在移走残留"
        }
    }

    var applyHint: String {
        switch self {
        case .uninstall:
            return "个人文件移到废纸篓；需管理员权限的文件经 root权限助手永久删除。"
        case .optimize:
            return "删除类进废纸篓；动作类直接执行；需管理员权限的文件经 root权限助手。"
        case .purge:
            return "默认进废纸篓；开启永久删除则直接删除；需管理员权限的文件经 root权限助手。"
        case .installer:
            return "默认进废纸篓；开启永久删除则直接删除；需管理员权限的文件经 root权限助手。"
        case .worktree:
            return "将整棵 Git checkout 送进废纸篓。不宣称可安全删除。需管理员权限的文件经 root权限助手。"
        case .agent:
            return "将 Agent 容器 / 会话 / 缓存残留送进废纸篓。不宣称可安全删除。需管理员权限的文件经 root权限助手。"
        }
    }

    var primaryActionTitle: String {
        switch self {
        case .uninstall: return "卸载所选"
        case .optimize: return "执行所选"
        case .purge: return "净化所选"
        case .installer: return "清理所选"
        case .worktree: return "清理所选"
        case .agent: return "清理所选"
        }
    }

    func confirmTitle(permanentDelete: Bool) -> String {
        let base: String
        switch self {
        case .uninstall:
            base = "个人文件移到废纸篓；需管理员权限的文件经 root权限助手永久删除（未就绪则跳过）"
        case .optimize:
            base = "将执行已选优化任务（删除类进废纸篓；root权限助手未就绪则跳过需管理员权限的文件）"
        case .purge:
            base = "将净化已选构建物（默认进废纸篓；需管理员权限的文件经 root权限助手，未就绪则跳过）"
        case .installer:
            base = "将清理已选安装包（默认进废纸篓；需管理员权限的文件经 root权限助手，未就绪则跳过）"
        case .worktree:
            base = "将删除已选的整棵 Git checkout（默认进废纸篓；需管理员权限的文件经 root权限助手，未就绪则跳过）。不宣称可安全删除"
        case .agent:
            base = "将删除已选的 Agent 容器 / 会话 / 缓存残留（默认进废纸篓；需管理员权限的文件经 root权限助手，未就绪则跳过）。不宣称可安全删除"
        }
        if permanentDelete && supportsPermanentDelete {
            return base + "。将永久删除，不可从废纸篓恢复"
        }
        return base
    }

    var confirmButton: String {
        switch self {
        case .uninstall: return "确认卸载"
        case .optimize: return "确认执行"
        case .purge: return "确认净化"
        case .installer: return "确认清理"
        case .worktree: return "确认清理"
        case .agent: return "确认清理"
        }
    }

    var resultTitle: String {
        switch self {
        case .uninstall: return "卸载完成"
        case .optimize: return "优化完成"
        case .purge: return "净化完成"
        case .installer: return "安装包清理完成"
        case .worktree: return "Worktree 清理完成"
        case .agent: return "Agent 清理完成"
        }
    }

    var planFilePrefix: String { "\(rawValue)-full" }
    var applyFilePrefix: String { "\(rawValue)-apply" }
}
```

不要改 `PlanModuleSession.handlePlanExit`（默认勾选留给 Task 5）。不要在 Kind 或 Session 里对条目路径调用 `FileManager.removeItem`。

- [ ] **Step 4: Run test to verify it passes**

```bash
xcodebuild test -scheme vole-macos -destination 'platform=macOS' \
  -only-testing:vole-macosTests/PlanModuleSessionTests
```

Expected: PASS（含既有 purge/installer 断言）

- [ ] **Step 5: Commit**

```bash
git add vole-macos/Plan/PlanModuleKind.swift \
  vole-macosTests/PlanModuleSessionTests.swift
git commit -m "$(cat <<'EOF'
feat: add worktree and agent plan module kinds

Extend PlanModuleKind with checkout-only and agent-residue copy,
permanent-delete support, and default-none selection flags.
EOF
)"
```

---

### Task 3: 侧栏十项 + 版本注入的 isAvailable

**Files:**
- Modify: `vole-macos/Shell/ShellModule.swift`
- Modify: `vole-macos/Shell/SidebarView.swift`
- Modify: `vole-macos/Shell/ShellView.swift`（补 `sidecarVersion:`；为穷尽 `switch selection` 必须同时挂 worktree/agent session 并路由到 `PlanModuleRootView`，否则本任务无法编译）
- Modify: `vole-macosTests/ShellViewTests.swift`

**Interfaces:**
- Consumes: `SidecarVersion.supportsWorktreeAgent(_:)`（Task 1）；`PlanModuleKind` 标题「Worktree」「Agent」（Task 2，侧栏标题与 Kind.title 一致）
- Produces: `ShellModule` cases 顺序 `clean, uninstall, optimize, purge, installer, worktree, agent, analyze, history, status`
- Produces: `func isAvailable(sidecarVersion: String) -> Bool`（**禁止**再写无参 `var isAvailable: Bool { true }` 且让 worktree/agent 恒 true）
- Produces: `func sidebarHelp(sidecarVersion: String) -> String`（不可用时 `Worktree · 需要内嵌 vole 2.20` / `Agent · 需要内嵌 vole 2.20`，不得含「即将推出」）
- Produces: `systemImage`：worktree `arrow.triangle.branch`；agent `cpu`（不与 `flame` / `chart.pie` / `chart.bar` 撞）

- [ ] **Step 1: Write the failing test**

替换 `ShellViewTests.swift` 全文：

```swift
import XCTest
@testable import vole_macos

final class ShellViewTests: XCTestCase {
    func test_moduleOrderStable() {
        XCTAssertEqual(
            ShellModule.allCases,
            [
                .clean, .uninstall, .optimize, .purge, .installer,
                .worktree, .agent, .analyze, .history, .status,
            ]
        )
    }

    func test_moduleTitles() {
        XCTAssertEqual(
            ShellModule.allCases.map(\.title),
            ["清理", "卸载", "优化", "净化", "安装包", "Worktree", "Agent", "分析", "历史", "状态"]
        )
    }

    func test_legacyModulesIgnoreSidecarVersion() {
        let old = "vole 2.19.0"
        for module in [ShellModule.clean, .uninstall, .optimize, .purge, .installer, .analyze, .history, .status] {
            XCTAssertTrue(module.isAvailable(sidecarVersion: old), module.rawValue)
            XCTAssertTrue(module.isAvailable(sidecarVersion: ""), module.rawValue)
        }
    }

    func test_worktreeAgentRequire220() {
        XCTAssertTrue(ShellModule.worktree.isAvailable(sidecarVersion: "vole 2.20.0"))
        XCTAssertTrue(ShellModule.agent.isAvailable(sidecarVersion: "vole-cli 2.20.1"))
        XCTAssertTrue(ShellModule.worktree.isAvailable(sidecarVersion: "vole 2.20.0-beta.1"))
        XCTAssertFalse(ShellModule.worktree.isAvailable(sidecarVersion: "vole 2.19.0"))
        XCTAssertFalse(ShellModule.agent.isAvailable(sidecarVersion: "vole 2.21.0"))
        XCTAssertFalse(ShellModule.worktree.isAvailable(sidecarVersion: ""))
        XCTAssertFalse(ShellModule.agent.isAvailable(sidecarVersion: "not-a-version"))
    }

    func test_unavailableHelpIsVersionNotComingSoon() {
        let help = ShellModule.worktree.sidebarHelp(sidecarVersion: "vole 2.19.0")
        XCTAssertEqual(help, "Worktree · 需要内嵌 vole 2.20")
        XCTAssertFalse(help.contains("即将推出"))
        XCTAssertEqual(
            ShellModule.agent.sidebarHelp(sidecarVersion: ""),
            "Agent · 需要内嵌 vole 2.20"
        )
        XCTAssertEqual(ShellModule.worktree.sidebarHelp(sidecarVersion: "vole 2.20.0"), "Worktree")
        XCTAssertEqual(ShellModule.clean.sidebarHelp(sidecarVersion: "vole 2.19.0"), "清理")
    }

    func test_systemImagesDoNotCollide() {
        XCTAssertEqual(ShellModule.worktree.systemImage, "arrow.triangle.branch")
        XCTAssertEqual(ShellModule.agent.systemImage, "cpu")
        XCTAssertEqual(ShellModule.purge.systemImage, "flame")
        XCTAssertEqual(ShellModule.analyze.systemImage, "chart.pie")
        XCTAssertEqual(ShellModule.status.systemImage, "chart.bar")
        let images = ShellModule.allCases.map(\.systemImage)
        XCTAssertEqual(Set(images).count, images.count)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
xcodebuild test -scheme vole-macos -destination 'platform=macOS' \
  -only-testing:vole-macosTests/ShellViewTests
```

Expected: FAIL（仍为八项；`isAvailable` 仍是无参 `Bool`）

- [ ] **Step 3: Write minimal implementation**

`ShellModule.swift`：

```swift
import Foundation

enum ShellModule: String, CaseIterable, Identifiable {
    case clean, uninstall, optimize, purge, installer, worktree, agent, analyze, history, status

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clean: return "清理"
        case .uninstall: return "卸载"
        case .optimize: return "优化"
        case .purge: return "净化"
        case .installer: return "安装包"
        case .worktree: return "Worktree"
        case .agent: return "Agent"
        case .analyze: return "分析"
        case .history: return "历史"
        case .status: return "状态"
        }
    }

    func isAvailable(sidecarVersion: String) -> Bool {
        switch self {
        case .worktree, .agent:
            return SidecarVersion.supportsWorktreeAgent(sidecarVersion)
        case .clean, .uninstall, .optimize, .purge, .installer, .analyze, .history, .status:
            return true
        }
    }

    func sidebarHelp(sidecarVersion: String) -> String {
        if isAvailable(sidecarVersion: sidecarVersion) {
            return title
        }
        return "\(title) · 需要内嵌 vole 2.20"
    }

    var systemImage: String {
        switch self {
        case .clean: return "sparkles"
        case .uninstall: return "trash"
        case .optimize: return "gauge"
        case .purge: return "flame"
        case .installer: return "shippingbox"
        case .worktree: return "arrow.triangle.branch"
        case .agent: return "cpu"
        case .analyze: return "chart.pie"
        case .history: return "clock"
        case .status: return "chart.bar"
        }
    }
}
```

`SidebarView.swift`：给视图加 `var sidecarVersion: String`，`moduleList` 改为：

```swift
    var sidecarVersion: String

    private var moduleList: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(ShellModule.allCases) { module in
                let available = module.isAvailable(sidecarVersion: sidecarVersion)
                SidebarNavRow(
                    title: module.title,
                    systemImage: module.systemImage,
                    isSelected: selection == module,
                    isEnabled: available,
                    help: module.sidebarHelp(sidecarVersion: sidecarVersion)
                ) {
                    guard module.isAvailable(sidecarVersion: sidecarVersion) else { return }
                    selection = module
                }
            }
        }
    }
```

仓库里只有一处 `SidebarView(`：`ShellView.swift` 第 61 行。`detailView` 的 `switch selection` 必须穷尽；加 `worktree` / `agent` case 后，本任务就要挂 session 并路由，否则 Task 3 提交无法编译。扫描门控、侧栏加宽、mascot 六路仍归 Task 4。

`ShellView.swift`：

1. 在 installer session 后增加：

```swift
    @StateObject private var worktreeSession = PlanModuleSession(kind: .worktree)
    @StateObject private var agentSession = PlanModuleSession(kind: .agent)
```

2. `SidebarView(` 增加 `sidecarVersion: session.voleVersion`（`CleanSession.voleVersion`，设置页同一探测源）。

3. `body` 追加 `.onAppear { session.refreshVersion() }`，避免侧栏一直拿到空版本、两项永远灰显。

4. `detailView` 在 `.installer` 与 `.analyze` 之间插入：

```swift
            case .worktree:
                PlanModuleRootView(session: worktreeSession, helperStatus: helperStatus)
            case .agent:
                PlanModuleRootView(session: agentSession, helperStatus: helperStatus)
```

`Text(title)` 不要加 `.lineLimit(1)` + `.truncationMode(.tail)`（规格：标题不得截成省略号）。

- [ ] **Step 4: Run test to verify it passes**

```bash
xcodebuild test -scheme vole-macos -destination 'platform=macOS' \
  -only-testing:vole-macosTests/ShellViewTests
```

Expected: PASS。此时 `ShellView` 若尚未传 `sidecarVersion`，先让工程编译通过（见 Step 3）。

- [ ] **Step 5: Commit**

```bash
git add vole-macos/Shell/ShellModule.swift \
  vole-macos/Shell/SidebarView.swift \
  vole-macos/Shell/ShellView.swift \
  vole-macosTests/ShellViewTests.swift
git commit -m "$(cat <<'EOF'
feat: expand sidebar to ten modules with version gate

Insert Worktree and Agent after installer and gate them on
sidecar 2.20.x instead of a parameterless isAvailable.
EOF
)"
```

---

### Task 4: 五态接线（session + 路由 + 扫描参数）

**Files:**
- Modify: `vole-macos/Shell/ShellView.swift`（`sidebarWidth`、mascot 六路；session/路由已在 Task 3）
- Modify: `vole-macos/Plan/PlanModuleSession.swift`
- Modify: `vole-macos/Plan/PlanModuleViews.swift`（`PlanModuleIdleView` 开始扫描门控）
- Modify: `vole-macosTests/PlanModuleSessionTests.swift`
- Modify: `vole-macosTests/MascotActivityTests.swift`（`resolve` 的 `plans` 从 4 个槽扩到 6 个，避免回归测试仍只传四路）

**Interfaces:**
- Consumes: `PlanModuleKind.worktree` / `.agent`（Task 2）；`SidecarVersion.supportsWorktreeAgent`（Task 1）；`SidebarView.sidecarVersion`（Task 3）
- Produces: Task 3 已有的 `worktreeSession` / `agentSession` 与 `PlanModuleRootView` 路由保持不变
- Produces: `nonisolated static func scanArguments(command: String, planPath: String) -> [String]`
- Produces: `nonisolated static func canStartScan(kind: PlanModuleKind, sidecarVersion: String) -> Bool`
- Produces: `startScan()` 在 `canStartScan == false` 时设 `errorMessage = "需要内嵌 vole 2.20"`、保持 `.idle`、**不**调用 `process.run`
- Produces: `sidebarWidth` 加宽到标题完整可见（推荐 `168`；「Worktree」比「安装包」宽）。不抬 `minHeight: 480`

- [ ] **Step 1: Write the failing test**

在 `PlanModuleSessionTests` 追加：

```swift
    @MainActor
    func test_scanArgumentsMatchCLI() {
        XCTAssertEqual(
            PlanModuleSession.scanArguments(command: "worktree", planPath: "/tmp/w.json"),
            ["worktree", "--plan", "--json-stream", "--plan-out", "/tmp/w.json"]
        )
        XCTAssertEqual(
            PlanModuleSession.scanArguments(command: "agent", planPath: "/tmp/a.json"),
            ["agent", "--plan", "--json-stream", "--plan-out", "/tmp/a.json"]
        )
    }

    @MainActor
    func test_applyArgumentsWorktreeAgent() {
        XCTAssertEqual(
            PlanModuleSession.applyArguments(
                command: "worktree",
                planPath: "/tmp/w.json",
                permanent: true
            ),
            ["worktree", "--apply", "/tmp/w.json", "--json-stream", "--permanent"]
        )
        XCTAssertEqual(
            PlanModuleSession.applyArguments(
                command: "agent",
                planPath: "/tmp/a.json",
                permanent: false
            ),
            ["agent", "--apply", "/tmp/a.json", "--json-stream"]
        )
    }

    func test_canStartScanRespectsVersionGate() {
        XCTAssertTrue(
            PlanModuleSession.canStartScan(kind: .purge, sidecarVersion: "vole 2.19.0")
        )
        XCTAssertTrue(
            PlanModuleSession.canStartScan(kind: .worktree, sidecarVersion: "vole 2.20.0")
        )
        XCTAssertFalse(
            PlanModuleSession.canStartScan(kind: .worktree, sidecarVersion: "vole 2.19.0")
        )
        XCTAssertFalse(
            PlanModuleSession.canStartScan(kind: .agent, sidecarVersion: "")
        )
    }

    @MainActor
    func test_startScanBlockedWhenSidecarNot220() {
        let session = PlanModuleSession(kind: .worktree)
        session.voleVersion = "vole 2.19.0"
        session.startScan()
        XCTAssertEqual(session.phase, .idle)
        XCTAssertEqual(session.errorMessage, "需要内嵌 vole 2.20")
    }
```

`MascotActivityTests.test_shellBusyFromCleanAndPlanPhases` 把四处 `plans: [.idle, .idle, .idle, .idle]`（及同类四元素数组）改成六元素，例如 `.idle` × 6，断言保持不变——先改测试会红如果 `resolve` 仍被 Shell 只喂四路（该测试本身不读 ShellView；改数组后测试仍应绿。此步目的是锁定「六路 plan 参与 mascot」的调用形状，实现时 `ShellView.sidebarMascotActivity` 必须传六路）。

- [ ] **Step 2: Run test to verify it fails**

```bash
xcodebuild test -scheme vole-macos -destination 'platform=macOS' \
  -only-testing:vole-macosTests/PlanModuleSessionTests
```

Expected: FAIL（无 `scanArguments` / `canStartScan`）

- [ ] **Step 3: Write minimal implementation**

`PlanModuleSession.swift`：在 `applyArguments` 旁增加，并改 `startScan`：

```swift
    nonisolated static func scanArguments(command: String, planPath: String) -> [String] {
        [command, "--plan", "--json-stream", "--plan-out", planPath]
    }

    nonisolated static func canStartScan(kind: PlanModuleKind, sidecarVersion: String) -> Bool {
        switch kind {
        case .worktree, .agent:
            return SidecarVersion.supportsWorktreeAgent(sidecarVersion)
        case .uninstall, .optimize, .purge, .installer:
            return true
        }
    }
```

`startScan()` 开头、在清状态之前：

```swift
        if !Self.canStartScan(kind: kind, sidecarVersion: voleVersion) {
            errorMessage = "需要内嵌 vole 2.20"
            phase = .idle
            return
        }
```

把 `process.run(arguments: [kind.command, "--plan", ...])` 换成 `Self.scanArguments(command: kind.command, planPath: planURL.path)`。

**禁止**在 `startScan` / `applySelected` 里对 `entry.path` 做 `FileManager.default.removeItem`。apply 仍只走 `applyArguments` + `PrivilegedApply`。

`PlanModuleIdleView` 的「开始扫描」：

```swift
                Button("开始扫描") { session.startScan() }
                    .buttonStyle(.borderedProminent)
                    .tint(VoleTheme.Colors.soil)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
                    .disabled(
                        !PlanModuleSession.canStartScan(
                            kind: session.kind,
                            sidecarVersion: session.voleVersion
                        )
                    )
```

`ShellView.swift`（session 与 `case .worktree` / `.agent` 路由已在 Task 3，不要删）：

- `sidebarWidth`：`148` → `168`（刚好放下「Worktree」；不要改用词，不要抬 `minHeight`）
- `sidebarMascotActivity` 的 `plans` 改为六路，顺序与侧栏 Plan 模块一致：

```swift
            plans: [
                uninstallSession.phase.mascotSessionPhase,
                optimizeSession.phase.mascotSessionPhase,
                purgeSession.phase.mascotSessionPhase,
                installerSession.phase.mascotSessionPhase,
                worktreeSession.phase.mascotSessionPhase,
                agentSession.phase.mascotSessionPhase,
            ]
```

确认 `SidebarView` 仍传 `sidecarVersion: session.voleVersion`，且 `body` 仍有 `.onAppear { session.refreshVersion() }`（Task 3 已加则不要删）。

`MascotActivityTests` 中该测试的 `plans` 数组改为 6 个 `.idle`（或与实现相同的六槽）。

- [ ] **Step 4: Run test to verify it passes**

```bash
xcodebuild test -scheme vole-macos -destination 'platform=macOS' \
  -only-testing:vole-macosTests/PlanModuleSessionTests \
  -only-testing:vole-macosTests/ShellViewTests \
  -only-testing:vole-macosTests/MascotActivityTests
```

Expected: PASS。`xcodebuild` 多个 `-only-testing` 是 OR；三个 target 都应跑到。

- [ ] **Step 5: Commit**

```bash
git add vole-macos/Shell/ShellView.swift \
  vole-macos/Plan/PlanModuleSession.swift \
  vole-macos/Plan/PlanModuleViews.swift \
  vole-macosTests/PlanModuleSessionTests.swift \
  vole-macosTests/MascotActivityTests.swift
git commit -m "$(cat <<'EOF'
feat: wire worktree and agent into plan five-state

Route the new sidebar items through PlanModuleSession and refuse
scans when the embedded sidecar is not 2.20.x.
EOF
)"
```

---

### Task 5: 候选页默认全不选

**Files:**
- Modify: `vole-macos/Plan/PlanModuleSession.swift`（`handlePlanExit` 与抽出的纯函数）
- Modify: `vole-macosTests/PlanModuleSessionTests.swift`

**Interfaces:**
- Consumes: `PlanModuleKind.selectsAllCandidatesByDefault`（Task 2）
- Produces: `nonisolated static func initialSelectedIDs(entries: [VolePlanEntry], selectsAllByDefault: Bool) -> Set<String>`
- Produces: `handlePlanExit` 在 `.success` 读 plan 后：`selectedIDs = Self.initialSelectedIDs(entries: entries, selectsAllByDefault: kind.selectsAllCandidatesByDefault)`
- Produces: uninstall/optimize/purge/installer 行为不变（仍全选）；worktree/agent 为 `[]`

- [ ] **Step 1: Write the failing test**

```swift
    func test_initialSelectedIDsRespectsDefaultFlag() {
        let entries = [
            VolePlanEntry(
                id: "w1", path: "/tmp/wt", label: "wt", size: 0,
                ruleID: "worktree:linked", skipReason: nil, dev: 1, ino: 2, mtime: 3
            ),
            VolePlanEntry(
                id: "w2", path: "/tmp/wt2", label: "wt2", size: 0,
                ruleID: "worktree:linked", skipReason: nil, dev: 1, ino: 3, mtime: 3
            ),
        ]
        XCTAssertEqual(
            PlanModuleSession.initialSelectedIDs(entries: entries, selectsAllByDefault: true),
            Set(["w1", "w2"])
        )
        XCTAssertEqual(
            PlanModuleSession.initialSelectedIDs(entries: entries, selectsAllByDefault: false),
            []
        )
    }
```

体积为 0 也必须原样进入集合逻辑（规格：全 0 诚实显示；本函数不因 size==0 改勾选）。

- [ ] **Step 2: Run test to verify it fails**

```bash
xcodebuild test -scheme vole-macos -destination 'platform=macOS' \
  -only-testing:vole-macosTests/PlanModuleSessionTests/test_initialSelectedIDsRespectsDefaultFlag
```

Expected: FAIL（`initialSelectedIDs` 未定义）

- [ ] **Step 3: Write minimal implementation**

在 `PlanModuleSession` 中、`applyArguments` 附近：

```swift
    nonisolated static func initialSelectedIDs(
        entries: [VolePlanEntry],
        selectsAllByDefault: Bool
    ) -> Set<String> {
        selectsAllByDefault ? Set(entries.map(\.id)) : []
    }
```

`handlePlanExit` 的 success 分支，现有：

```swift
                entries = plan.entries.filter { $0.skipReason == nil }
                selectedIDs = Set(entries.map(\.id))
```

改为：

```swift
                entries = plan.entries.filter { $0.skipReason == nil }
                selectedIDs = Self.initialSelectedIDs(
                    entries: entries,
                    selectsAllByDefault: kind.selectsAllCandidatesByDefault
                )
```

不要删 `PlanModuleCandidatesView` 里的「全选」「全不选」按钮。不要加「全选并跳过确认」。不要改 `CleanSession.handlePlanExit`（Clean 不在本里程碑）。

- [ ] **Step 4: Run test to verify it passes**

```bash
xcodebuild test -scheme vole-macos -destination 'platform=macOS' \
  -only-testing:vole-macosTests/PlanModuleSessionTests
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add vole-macos/Plan/PlanModuleSession.swift \
  vole-macosTests/PlanModuleSessionTests.swift
git commit -m "$(cat <<'EOF'
fix: leave worktree and agent candidates unchecked

Honor selectsAllCandidatesByDefault so leftover checkouts and
agent residue never preselect after a plan scan.
EOF
)"
```

---

### Task 6: 风险文案与不可用提示（UI 锁词）

**Files:**
- Modify: `vole-macos/Plan/PlanModuleViews.swift`（空闲区必须能看到 idleCaption；候选页体积继续走 `ByteFormat.string`，size 0 也显示）
- Modify: `vole-macos/Shell/SidebarView.swift`（若 Task 3 已改 help，本任务只加锁词测试）
- Modify: `vole-macosTests/PlanModuleSessionTests.swift`
- Modify: `vole-macosTests/ShellViewTests.swift`

**Interfaces:**
- Consumes: Task 2 `idleCaption` / `confirmTitle`；Task 3 `sidebarHelp`
- Produces: 空闲 `SoilPanel` caption 仍是 `session.kind.idleCaption`（已含「不宣称可安全删除」）
- Produces: 测试锁死禁止词：不得出现「放心删」「已过期」「可安全移除」「即将推出」（后一项仅针对 worktree/agent 不可用 help）
- Produces: 候选页 `ByteFormat.string(0)` 诚实显示（不因 0 改文案为「可删」）

- [ ] **Step 1: Write the failing test**

在 `PlanModuleSessionTests`：

```swift
    func test_riskCopyForbidsSafeDeletePromises() {
        let blobs = [
            PlanModuleKind.worktree.idleCaption,
            PlanModuleKind.agent.idleCaption,
            PlanModuleKind.worktree.applyHint,
            PlanModuleKind.agent.applyHint,
            PlanModuleKind.worktree.confirmTitle(permanentDelete: false),
            PlanModuleKind.agent.confirmTitle(permanentDelete: false),
        ]
        for text in blobs {
            XCTAssertTrue(text.contains("不宣称可安全删除"), text)
            XCTAssertFalse(text.contains("放心删"), text)
            XCTAssertFalse(text.contains("可安全移除"), text)
            XCTAssertFalse(text.contains("即将推出"), text)
        }
    }
```

在 `ShellViewTests`：

```swift
    func test_worktreeAgentHelpNeverComingSoon() {
        let versions = ["", "vole 2.19.0", "vole 2.20.0", "garbage"]
        for raw in versions {
            XCTAssertFalse(
                ShellModule.worktree.sidebarHelp(sidecarVersion: raw).contains("即将推出")
            )
            XCTAssertFalse(
                ShellModule.agent.sidebarHelp(sidecarVersion: raw).contains("即将推出")
            )
        }
    }
```

若 Task 2/3 已写对文案，这些测试在 Step 2 可能已经绿。若绿：仍跑一遍作为锁；不要为了造红而改规格用词。若红：只改 Kind/Sidebar 用词，不改规格。

- [ ] **Step 2: Run test to verify it fails**

```bash
xcodebuild test -scheme vole-macos -destination 'platform=macOS' \
  -only-testing:vole-macosTests/PlanModuleSessionTests/test_riskCopyForbidsSafeDeletePromises \
  -only-testing:vole-macosTests/ShellViewTests/test_worktreeAgentHelpNeverComingSoon
```

Expected: 若 Task 2/3 已落地规格用词 → PASS（本步记录为锁词回归）。若 help 仍含「即将推出」→ FAIL，进入 Step 3。

- [ ] **Step 3: Write minimal implementation**

确认 `PlanModuleIdleView` 仍是：

```swift
            SoilPanel(valueText: "—", caption: session.kind.idleCaption)
```

确认 `PlanModuleCandidatesView` 仍用 `ByteFormat.string(selectedBytes)`，不要对 `selectedBytes == 0` 改写成「可安全删除」或隐藏体积。

确认 `SidebarView` 的 `help:` 只走 `sidebarHelp(sidecarVersion:)`，删除任何 `"\(module.title) · 即将推出"` 字面量（worktree/agent 不可用路径）。

`PlanModuleCandidatesView` 保留「全选」「全不选」两个独立 Button，不要合并成「全选并跳过确认」。

- [ ] **Step 4: Run test to verify it passes**

```bash
xcodebuild test -scheme vole-macos -destination 'platform=macOS' \
  -only-testing:vole-macosTests/PlanModuleSessionTests \
  -only-testing:vole-macosTests/ShellViewTests
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add vole-macos/Plan/PlanModuleViews.swift \
  vole-macos/Shell/SidebarView.swift \
  vole-macosTests/PlanModuleSessionTests.swift \
  vole-macosTests/ShellViewTests.swift
git commit -m "$(cat <<'EOF'
test: lock worktree and agent risk copy

Keep idle, confirm, and sidebar help from claiming safe delete
or papering over a sidecar version mismatch.
EOF
)"
```

若 Step 3 无产品文件 diff、仅有新测试，就只 add 测试文件。

---

### Task 7: README 五语能力表

**Files:**
- Modify: `README.md`（Features 表，Installer 与 Analyze 之间插入两行）
- Modify: `README.zh-CN.md`（「能做什么」表，安装包与分析之间）
- Modify: `README.zh-TW.md`（安裝套件与分析之间）
- Modify: `README.ja.md`（インストーラ与分析之间）
- Modify: `README.ko.md`（설치 파일与분석之间）

**Interfaces:**
- Consumes: 规格 §4.1 / §4.5 能力描述（整棵 checkout；Agent ≠ checkout；不宣称可安全删；默认废纸篓）
- Produces: 五语各加 **Worktree** / **Agent** 行；**不得**出现「已随 0.2.0 发布」或「shipped in 0.2.0」
- Produces: 现有「当前版本 v0.2.0」发行说明行保持原样（那是已发布桌面版，不是本里程碑宣称）

- [ ] **Step 1: Write the failing test**

用仓库内检查代替 Swift 测试（README 不在 app target）。在实现前先跑，确认现在会失败：

```bash
for f in README.md README.zh-CN.md README.zh-TW.md README.ja.md README.ko.md; do
  echo "== $f"
  grep -n 'Worktree' "$f" || true
done
! grep -R -n '已随 0.2.0 发布\|shipped in 0.2.0\|已隨 0.2.0 發佈' \
  README.md README.zh-CN.md README.zh-TW.md README.ja.md README.ko.md
```

Expected: 五文件当前无 Worktree 行（第一步的 `grep Worktree` 无匹配）。禁止词 grep 退出 0（`! grep` 在无匹配时成功）。

再写一条应失败的断言（实现前执行，退出非 0）：

```bash
test "$(grep -c 'Worktree' README.md)" -ge 1
```

Expected: FAIL（`test` 退出 1）

- [ ] **Step 2: Run test to verify it fails**

就是上一行 `test "$(grep -c 'Worktree' README.md)" -ge 1`。Expected: exit 1。

- [ ] **Step 3: Write minimal implementation**

在 **Installer / 安装包 / 安裝套件 / インストーラ / 설치 파일** 行之后、**Analyze / 分析 / 分析 / 분석** 行之前插入（不要改其它八行）：

`README.md`：

```markdown
| **Worktree** | Find leftover Git worktree checkouts (the whole checkout). Not claimed safe to delete. Trash by default. |
| **Agent** | Find leftover agent containers, sessions, and caches (not Git checkouts). Trash by default. |
```

`README.zh-CN.md`：

```markdown
| **Worktree** | 扫描遗留的 Git worktree，将整棵 checkout 送进废纸篓。不宣称可安全删除。 |
| **Agent** | 扫描 Agent 容器、会话与缓存残留（不是 Git checkout）。默认进废纸篓。不宣称可安全删除。 |
```

`README.zh-TW.md`：

```markdown
| **Worktree** | 掃描遺留的 Git worktree，將整棵 checkout 送進廢紙簍。不宣稱可安全刪除。 |
| **Agent** | 掃描 Agent 容器、工作階段與快取殘留（不是 Git checkout）。預設進廢紙簍。不宣稱可安全刪除。 |
```

`README.ja.md`：

```markdown
| **Worktree** | 残った Git worktree のチェックアウト一式を検出。安全削除とは言いません。既定はゴミ箱。 |
| **Agent** | Agent のコンテナ・セッション・キャッシュ残骸を検出（Git checkout ではない）。既定はゴミ箱。 |
```

`README.ko.md`：

```markdown
| **Worktree** | 남은 Git worktree 체크아웃 전체를 찾습니다. 안전 삭제를 주장하지 않습니다. 기본은 휴지통. |
| **Agent** | Agent 컨테이너·세션·캐시 잔여물을 찾습니다(Git checkout 아님). 기본은 휴지통. |
```

不要改「当前版本 **v0.2.0**」那一行。不要写「已随 0.2.0 发布」「本版已包含 Worktree」。不要 bump `MARKETING_VERSION`。

- [ ] **Step 4: Run test to verify it passes**

```bash
for f in README.md README.zh-CN.md README.zh-TW.md README.ja.md README.ko.md; do
  test "$(grep -c 'Worktree' "$f")" -ge 1
  test "$(grep -c 'Agent' "$f")" -ge 1
done
! grep -R -n '已随 0.2.0 发布\|shipped in 0.2.0\|已隨 0.2.0 發佈' \
  README.md README.zh-CN.md README.zh-TW.md README.ja.md README.ko.md
```

Expected: 循环全部 exit 0；禁止词 `! grep` 成功。

- [ ] **Step 5: Commit**

```bash
git add README.md README.zh-CN.md README.zh-TW.md README.ja.md README.ko.md
git commit -m "$(cat <<'EOF'
docs: list Worktree and Agent in five README languages

Document leftover checkout and agent-residue cleanup without
claiming they shipped in desktop 0.2.0.
EOF
)"
```

---

### Task 8: 截图（最后，不阻塞前七项）

**Files:**
- Create or replace: `images/sidebar-ten.png`（主侧栏十项，Worktree / Agent 标题完整可见、无省略号）
- Optional replace: `images/clean-idle.png`（若新侧栏出现在同一窗）
- Modify: `README.md` / `README.zh-CN.md` / `README.zh-TW.md` / `README.ja.md` / `README.ko.md` 的 Screenshots 段（仅当新增文件时加一张图；不要删现有 `clean-idle.png` / `candidates.png`）

**Interfaces:**
- Consumes: Task 3–4 已能运行的十项侧栏（本机 `xcodebuild -scheme vole-macos -configuration Debug -destination 'platform=macOS' build` 且 embed 为 2.20.0）
- Produces: 至少一张侧栏十项截图；README 用相对路径 `images/sidebar-ten.png`
- Produces: 截图说明不写「0.2.0 已发布」；本任务不打 tag、不建 Release、不改 `MARKETING_VERSION`

- [ ] **Step 1: Write the failing test**

```bash
test -f images/sidebar-ten.png
```

Expected: FAIL（文件不存在，exit 1）

- [ ] **Step 2: Run test to verify it fails**

同上。Expected: exit 1。

- [ ] **Step 3: Capture and link**

1. Debug 构建并打开 App（embed 必须通过 Task 1 的 2.20.0 门）。
2. 窗口默认选「清理」。侧栏应完整显示：清理、卸载、优化、净化、安装包、Worktree、Agent、分析、历史、状态。
3. 若「Worktree」被裁切：回到 `ShellView.sidebarWidth` 再加宽（仍不改用词、不抬 `minHeight`），重新截。
4. 截图保存为 `images/sidebar-ten.png`（与现有 `images/clean-idle.png` 同目录；不要用「即将推出」灰条当主图，除非故意拍 2.19 不可用态——本任务主图应是 2.20.0 可用态）。
5. 五语 README 的 Screenshots 段，在现有两图之后追加（路径相同）：

`README.md`：

```markdown
<p align="center">
  <img src="images/sidebar-ten.png" alt="Ten sidebar modules including Worktree and Agent" width="48%" />
</p>
```

`README.zh-CN.md`：`alt="十项侧栏，含 Worktree 与 Agent"`  
`README.zh-TW.md`：`alt="十項側欄，含 Worktree 與 Agent"`  
`README.ja.md`：`alt="Worktree と Agent を含む 10 項目サイドバー"`  
`README.ko.md`：`alt="Worktree와 Agent가 포함된 사이드바 10항목"`

无截图工具、无法开 GUI 时：不要用空白 PNG 凑数；停在本任务并写明阻塞。不要为此发版。

- [ ] **Step 4: Run test to verify it passes**

```bash
test -f images/sidebar-ten.png
test "$(wc -c < images/sidebar-ten.png)" -gt 1000
for f in README.md README.zh-CN.md README.zh-TW.md README.ja.md README.ko.md; do
  grep -q 'images/sidebar-ten.png' "$f"
done
```

Expected: 全部 exit 0。

- [ ] **Step 5: Commit**

```bash
git add images/sidebar-ten.png \
  README.md README.zh-CN.md README.zh-TW.md README.ja.md README.ko.md
git commit -m "$(cat <<'EOF'
docs: add ten-item sidebar screenshot

Show Worktree and Agent in the main sidebar after the five-state
wiring, without claiming a desktop release.
EOF
)"
```

---

## Spec coverage (self-review)

| 规格 | 任务 |
|---|---|
| 侧栏十项顺序 §4.1 | Task 3 |
| SF Symbol / 中文标题 Worktree·Agent | Task 3 |
| 标题不截断、可加宽侧栏 | Task 4 `sidebarWidth`；Task 8 目视 |
| `isAvailable` 注入版本、非 2.20.x 灰显 | Task 1 + 3 + 4 |
| 不可用 help 不是「即将推出」 | Task 3 + 6 |
| `PlanModuleKind` + `PlanModuleSession` 五态 | Task 2 + 4 |
| `worktree\|agent --plan --json-stream --plan-out` / `--apply` / `--permanent` | Task 4 |
| 默认全不选 | Task 2 开关 + Task 5 |
| 废纸篓默认、永久开关默认关 | 既有 `permanentDelete = false`；Task 2 `supportsPermanentDelete` |
| §4.5 文案 +「不宣称可安全删除」 | Task 2 + 6 |
| 无「全选并跳过确认」 | Task 5/6 明确保留两按钮、不加合并动作 |
| sidecar 恰好 2.20.0；CI `v2.20.0` | Task 1 |
| 不 bump `schema_version` | Global Constraints + Task 1 禁止改 `PlanIO` |
| 无第二条删除路径 | Task 2/4 禁止对条目 `FileManager.removeItem` |
| Helper 语义与净化/安装包相同 | 复用 `PlanModuleSession.applySelected` + `PrivilegedApply`，无新 API |
| README 五语、不写已随 0.2.0 发布 | Task 7 |
| 截图不阻塞前序 | Task 8 最后 |
| 不发版、不 bump 0.2.0、CLI 仓零改 | Global Constraints；各 commit 不含 `MARKETING_VERSION` / vole 仓 |
| 验收 §6.10 单元测试 | Task 1–6 |

不在本计划实现、也不另开桌面删除逻辑：CLI 硬排除（主工作区 / cwd / Agent 不认领 checkout）仍只在 sidecar 内执行。UI 不重写认领规则。若实现时发现 Plan JSON 缺字段：停下来另开 design，不 bump `schema_version`。
