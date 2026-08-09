# Sidebar Modules MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use wukong-code:executing-plans (inline; default-yes). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把侧栏卸载 / 优化 / 状态与设置从「即将推出」做成可用最小产品面，复用 Clean 的 Session + RootView + SidecarRunner 模式。

**Architecture:** CLI（`vole uninstall` / `optimize` / `status`）已具备与 Clean 同形的 Plan/Report/NDJSON（`schema_version=1`）及 StatusSnapshot。桌面端新增 `PlanModuleSession`（参数化 CLI 动词）服务卸载/优化；`StatusSession` 消费 `status --json`；设置以 sheet 归位 Helper / FDA / 关于。不改兄弟仓协议；不碰公证。

**Tech Stack:** SwiftUI、XCTest、Foundation Process sidecar、既有 `VoleProtocol` / `PrivilegedApply` / `VoleTheme`。

## Global Constraints

- 保持 Clean 行为不被破坏（不重构 `CleanSession` 本体）
- 协议 `schema_version` = 1；sidecar 仍走 `vole-cli`
- 无假数据：sidecar 失败展示真实错误/空态
- 视觉延续田鼠工坊（VoleTheme / SoilPanel）
- 不做公证 / Sparkle / MAS；不开 PR，task 级 commit

## File Map

| Path | Role |
|---|---|
| `vole-macos/Shell/ShellModule.swift` | `isAvailable` 全开 |
| `vole-macos/Shell/SidebarView.swift` | 设置按钮 → sheet |
| `vole-macos/Shell/SettingsSheet.swift` | Helper / FDA / 版本 |
| `vole-macos/Shell/ShellView.swift` | 路由四模块 + settings binding |
| `vole-macos/Plan/PlanModuleSession.swift` | 通用 plan/apply session |
| `vole-macos/Plan/PlanModuleRootView.swift` | 五态宿主（复用 Clean 视觉骨架） |
| `vole-macos/Plan/PlanModuleViews.swift` | idle/scanning/candidates/applying/result |
| `vole-macos/Status/StatusSnapshot.swift` | StatusSnapshot 子集解码 |
| `vole-macos/Status/StatusSession.swift` | `status --json` 轮询 |
| `vole-macos/Status/StatusRootView.swift` | 状态仪表盘 |
| `vole-macosTests/ShellViewTests.swift` | 可用性断言更新 |
| `vole-macosTests/StatusSnapshotTests.swift` | JSON 解码 |
| `vole-macosTests/PlanModuleSessionTests.swift` | 命令参数 / 空态 |
| `README.md` | 最小功能面说明 |

---

### Task 1: 启用侧栏模块 + 设置面板

**Files:**
- Modify: `vole-macos/Shell/ShellModule.swift`
- Modify: `vole-macos/Shell/SidebarView.swift`
- Create: `vole-macos/Shell/SettingsSheet.swift`
- Modify: `vole-macos/Shell/ShellView.swift`
- Modify: `vole-macosTests/ShellViewTests.swift`
- Modify: `vole-macos/vole_macosApp.swift` / `ContentView.swift`（若需注入 helper/version）

**Interfaces:**
- Produces: `ShellModule.isAvailable == true` for all; `SettingsSheet(helperStatus:versionProvider:)`; `SidebarView` / `ShellView` show settings via `@Binding var showSettings`

- [ ] **Step 1: Update failing test**

```swift
func test_allModulesAvailable() {
    XCTAssertEqual(ShellModule.allCases.map(\.isAvailable), [true, true, true, true])
}
```

- [ ] **Step 2: Implement**

`isAvailable { true }`；`SettingsSheet` 含 `HelperStatusCard`、FDA 探测按钮、sidecar 版本；`moreRow` 设 `showSettings = true`；`ShellView` `.sheet` 呈现。`ComingSoonView` 删除或不再路由。

- [ ] **Step 3: Test + commit**

```bash
xcodebuild test -scheme vole-macos -destination 'platform=macOS' -only-testing:vole-macosTests/ShellViewTests
git add … && git commit -m "feat: enable sidebar modules and settings sheet"
```

---

### Task 2: StatusSnapshot + Status UI

**Files:**
- Create: `vole-macos/Status/StatusSnapshot.swift`
- Create: `vole-macos/Status/StatusSession.swift`
- Create: `vole-macos/Status/StatusRootView.swift`
- Create: `vole-macosTests/StatusSnapshotTests.swift`
- Modify: `ShellView` 路由 `.status`

**Interfaces:**
- Consumes: `VoleProcess.run(arguments: ["status", "--json"], …)`
- Produces: `StatusSession.refresh()` / `startLive()` / `stopLive()`；`StatusRootView`

- [ ] **Step 1: Decode test** with fixture JSON containing `health_score`, `cpu.usage`, `memory.used_percent`, `disks[]`, `host`
- [ ] **Step 2: Implement decode + session + dashboard**（健康分、CPU/内存、磁盘、错误态、刷新）
- [ ] **Step 3: Test + commit** `feat: add status module with status --json`

---

### Task 3: PlanModuleSession（卸载 / 优化共用）

**Files:**
- Create: `vole-macos/Plan/PlanModuleSession.swift`
- Create: `vole-macos/Plan/PlanModuleRootView.swift`
- Create: `vole-macos/Plan/PlanModuleViews.swift`
- Create: `vole-macosTests/PlanModuleSessionTests.swift`
- Modify: `ShellView` 注入 sessions

**Interfaces:**
- Consumes: `VoleProcess`, `PlanIO`, `PrivilegedApply`, `VoleStreamEvent`（与 Clean 同形）
- Produces: `PlanModuleSession(command: "uninstall"|"optimize", …)` with same Phase enum as Clean; `startScan` / `applySelected` / `cancel` / `reset`

CLI args mirror Clean:
- plan: `"\(command)", "--plan", "--json-stream", "--plan-out", path`
- apply: `"\(command)", "--apply", path, "--json-stream"`

Privileged partition identical to Clean. Copy 用 `PlanModuleKind` 提供中文标题与主 CTA。

- [ ] **Step 1: Unit test** `PlanModuleKind.uninstall.command == "uninstall"` 等
- [ ] **Step 2: Implement session + views**（idle→scan→candidates→apply→result）
- [ ] **Step 3: Wire ShellView** + commit `feat: add uninstall and optimize plan modules`

---

### Task 4: README + 全量测试

**Files:**
- Modify: `README.md`（删除「Uninstall UI 尚未落地」；简述四模块）

- [ ] **Step 1: README 最小改动**
- [ ] **Step 2: `xcodebuild test -scheme vole-macos -destination 'platform=macOS'`**
- [ ] **Step 3: commit** `docs: note sidebar modules MVP in README`

---

## Spec coverage

| 需求 | Task |
|---|---|
| Uninstall 扫描/展示/执行用户域 | 3 |
| Helper 深度删除扩展点 | 3（复用 PrivilegedApply） |
| Optimize | 3 |
| Status | 2 |
| Settings 非空 | 1 |
| isAvailable | 1 |
| 无假数据 | 2/3 错误态 |
| 测试 | 1–3 |
| 不破坏 Clean | 不改 CleanSession |

## Execution

默认 **Inline Execution**（用户规则 / 本会话偏好）。
