# Vole macOS UI（壳 + Clean） Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use wukong-code:subagent-driven-development (recommended) or wukong-code:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 按已批准 spec 落地「田鼠工坊」壳与 Clean 五态 UI：设计 token、土层条、`NavigationSplitView` 壳、五态改造、可访问性。

**Architecture:** 纯 SwiftUI 薄壳。新增 `Design/` token 与 `SoilStrataView` / `SidebarView`；`ContentView` 改为壳；Clean 五个视图在既有 `CleanSession` 状态机上改视觉，不改 sidecar / plan / 特权助手逻辑。

**Tech Stack:** SwiftUI（macOS）、Xcode target `vole-macos` / `vole-macosTests`、logo asset 从 `.wukong-code/brainstorm/71880-1786199536/content/files/vole-logo.png` 拷入。

## Global Constraints

- **不改** sidecar / Plan / Report / 冻结协议；CLI `vole` 仓零改
- **不改** 特权助手安全边界（白名单 fail-closed、`PathAuthorization`）
- Fur 固定 `#C99971`；Soil `#7D5D4A`；Burrow `#2C211C`；Clay `#F6F0E8`；Blush `#F4A6A1`；Molehill `#E8D5C0`
- 侧栏在浅/深模式恒定 Burrow；土层条需尊重 Reduce Motion
- 用户可见文案用 `LocalizedStringKey`（本仓现状直接中文字符串，保持一致、可被本地化系统拾取）
- 吉祥物仅出现在空闲 / 扫描中 / 结果成功；候选勾选与确认框不出现
- 每 task 完成后 commit；改 Swift 后跑相关测试

---

### Task 1: 设计 token + logo asset

**Files:**
- Create: `vole-macos/Design/VoleTheme.swift`
- Modify: `vole-macos/Assets.xcassets`（新增 `VoleLogo.imageset`，从 brainstorm 拷图）
- Test: `vole-macosTests/VoleThemeTests.swift`

**Interfaces:**
- Consumes: 无
- Produces: `enum VoleTheme { static let fur: Color; soil: Color; burrow: Color; clay: Color; blush: Color; molehill: Color; ink: Color; contentBackground: Color }`；`extension Color { init(hex: UInt32, alpha: Double = 1) }`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
import SwiftUI
@testable import vole_macos

final class VoleThemeTests: XCTestCase {
    func test_furMatchesLockedBrandValue() {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        XCTAssertTrue(NSColor(VoleTheme.fur).getRed(&r, green: &g, blue: &b, alpha: &a))
        XCTAssertEqual(round(r * 255), 201, accuracy: 1)
        XCTAssertEqual(round(g * 255), 153, accuracy: 1)
        XCTAssertEqual(round(b * 255), 113, accuracy: 1)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: Xcode Test `VoleThemeTests`（`xcodebuild test -scheme vole-macos -destination 'platform=macOS' -only-testing:vole-macosTests/VoleThemeTests`）
Expected: FAIL — `VoleTheme` 未定义

- [ ] **Step 3: Write minimal implementation**

```swift
import SwiftUI

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

enum VoleTheme {
    static let burrow = Color(hex: 0x2C211C)
    static let soil = Color(hex: 0x7D5D4A)
    static let fur = Color(hex: 0xC99971)
    static let clay = Color(hex: 0xF6F0E8)
    static let blush = Color(hex: 0xF4A6A1)
    static let molehill = Color(hex: 0xE8D5C0)
    static let ink = Color(hex: 0x1C1613)
    static let contentBackground = Color(light: 0xF6F0E8, dark: 0x1C1613)
}

private extension Color {
    init(light: UInt32, dark: UInt32) {
        self = Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return NSColor(hex: isDark ? dark : light)
        })
    }
}

private extension NSColor {
    convenience init(hex: UInt32) {
        self.init(
            calibratedRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
```

将 `VoleTheme.swift` 加入 target；把 `vole-logo.png` 拷为 `Assets.xcassets/VoleLogo.imageset`（`Contents.json` 指向该图）。

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme vole-macos -destination 'platform=macOS' -only-testing:vole-macosTests/VoleThemeTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add vole-macos/Design/VoleTheme.swift vole-macos/Assets.xcassets vole-macosTests/VoleThemeTests.swift vole-macos.xcodeproj/project.pbxproj
git commit -m "feat: add vole design tokens and logo asset"
```

---

### Task 2: 签名组件 SoilStrataView

**Files:**
- Create: `vole-macos/Design/SoilStrataView.swift`
- Test: `vole-macosTests/SoilStrataViewTests.swift`

**Interfaces:**
- Consumes: `VoleTheme`
- Produces: `struct SoilStrataView: View { init(fraction: Double?, animated: Bool = true) }`（`fraction`：`nil`=未扫虚位；`0...1`=已选/进度）

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
import SwiftUI
@testable import vole_macos

final class SoilStrataViewTests: XCTestCase {
    func test_fractionClampedToZeroOne() {
        let view = SoilStrataView(fraction: 1.4)
        XCTAssertEqual(view.clampedFraction, 1.0, accuracy: 0.001)
    }
    func test_nilFractionIsIdle() {
        XCTAssertNil(SoilStrataView(fraction: nil).clampedFraction)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme vole-macos -only-testing:vole-macosTests/SoilStrataViewTests -destination 'platform=macOS'`
Expected: FAIL

- [ ] **Step 3: Write minimal implementation**

```swift
import SwiftUI

struct SoilStrataView: View {
    let fraction: Double?
    var animated: Bool = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var clampedFraction: Double? {
        fraction.map { min(max($0, 0), 1) }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(VoleTheme.molehill.opacity(0.35))
                if let f = clampedFraction {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(
                            colors: [VoleTheme.soil, Color(hex: 0xA67C52), VoleTheme.fur, VoleTheme.molehill],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: max(geo.size.width * f, 12))
                        .animation(reduceMotion || !animated ? nil : .easeInOut(duration: 0.35), value: f)
                }
            }
        }
        .frame(height: 12)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .accessibilityLabel(clampedFraction.map { "可回收体积占比 \(Int($0 * 100))%" } ?? "待扫描")
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme vole-macos -only-testing:vole-macosTests/SoilStrataViewTests -destination 'platform=macOS'`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add vole-macos/Design/SoilStrataView.swift vole-macosTests/SoilStrataViewTests.swift vole-macos.xcodeproj/project.pbxproj
git commit -m "feat: add SoilStrataView signature component"
```

---

### Task 3: 壳（ShellView + SidebarView）

**Files:**
- Create: `vole-macos/Shell/ShellView.swift`、`vole-macos/Shell/SidebarView.swift`
- Modify: `vole-macos/ContentView.swift`
- Test: `vole-macosTests/ShellViewTests.swift`

**Interfaces:**
- Consumes: `CleanSession`、`HelperStatusModel`、`VoleTheme`
- Produces: `enum ShellModule: String, CaseIterable, Identifiable { case clean, uninstall, optimize, status }`（含 `title`、`isAvailable`）；`struct ShellView: View { init(session: CleanSession, helperStatus: HelperStatusModel) }`

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import vole_macos

final class ShellViewTests: XCTestCase {
    func test_onlyCleanAvailable() {
        XCTAssertEqual(ShellModule.allCases.map(\.isAvailable), [true, false, false, false])
        XCTAssertEqual(ShellModule.allCases.map(\.title), ["清理", "卸载", "优化", "状态"])
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme vole-macos -only-testing:vole-macosTests/ShellViewTests -destination 'platform=macOS'`
Expected: FAIL

- [ ] **Step 3: Write minimal implementation**

`SidebarView.swift`：侧栏顶部「地道口」圆形凹槽（`VoleTheme.burrow` 底 + 径向渐变 + 内阴影）放 `VoleLogo`；列出 `ShellModule.allCases`——`clean` 高亮 Fur，其余 `opacity(0.4)` + `soon`。底部「更多 · 设置」。

`ShellView.swift`：

```swift
import SwiftUI

struct ShellView: View {
    @ObservedObject var session: CleanSession
    @ObservedObject var helperStatus: HelperStatusModel
    @State private var selection: ShellModule = .clean

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
                .frame(minWidth: 188)
        } detail: {
            Group {
                switch selection {
                case .clean:
                    CleanRootView(session: session, helperStatus: helperStatus)
                case .uninstall, .optimize, .status:
                    ComingSoonView(module: selection)
                }
            }
            .background(VoleTheme.contentBackground)
            .frame(minWidth: 520, minHeight: 420)
        }
        .navigationSplitViewStyle(.balanced)
    }
}
```

`ContentView.swift` 改为 `ShellView(session: session, helperStatus: helperStatus)`。`ComingSoonView`：模块名 + 「即将推出」。

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme vole-macos -only-testing:vole-macosTests/ShellViewTests -destination 'platform=macOS'`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add vole-macos/Shell vole-macos/ContentView.swift vole-macosTests/ShellViewTests.swift vole-macos.xcodeproj/project.pbxproj
git commit -m "feat: add app shell with sidebar and Clean module"
```

---

### Task 4: Clean 五态改造（空闲 / 扫描中）

**Files:**
- Modify: `vole-macos/Clean/CleanIdleView.swift`、`vole-macos/Clean/CleanScanningView.swift`
- Create: `vole-macos/Design/SoilPanel.swift`（土层条 + tabular 数字 + caption 的容器）

**Interfaces:**
- Consumes: `SoilStrataView`、`VoleTheme`、`ByteFormat`、`HelperStatusCard`
- Produces: `struct SoilPanel: View { init(fraction: Double?, valueText: String, caption: String) }`

- [ ] **Step 1: Write the failing test**

`SoilPanel` 快照/存在性测试（或并入 VoleThemeTests 断言 `caption` 可注入）。轻量断言：构造不崩溃、`accessibilityLabel` 含「可回收」。

Run: `xcodebuild test -scheme vole-macos -only-testing:vole-macosTests/SoilStrataViewTests -destination 'platform=macOS'`
Expected: FAIL（未定义）

- [ ] **Step 2: Write minimal implementation**

空闲（`CleanIdleView`）：标题 `翻土找缓存` + 田鼠图（`Image("VoleLogo")`）；`SoilPanel(fraction: nil, valueText: "—", caption: "可回收层 · 待扫描")`；说明文案；`HelperStatusCard` 保留；主 CTA `开始扫描`（Soil 底、胶囊/圆角）；`sidecar`/FDA 状态行。

扫描中（`CleanScanningView`）：标题 `正在翻找`；`SoilPanel(fraction: nil)` 配「呼吸」修饰（非 Reduce Motion 时透明度动画）；`已扫 \(progressScanned)`（tabular）+ `progressCurrent`（monospace、截断）；`取消`。

- [ ] **Step 3: Run test to verify it passes**

Run: `xcodebuild test -scheme vole-macos -only-testing:vole-macosTests/SoilStrataViewTests -destination 'platform=macOS'`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add vole-macos/Clean/CleanIdleView.swift vole-macos/Clean/CleanScanningView.swift vole-macos/Design/SoilPanel.swift
git commit -m "feat: restyle Clean idle and scanning with soil strata"
```

---

### Task 5: 候选列表（含需助手标记 / 跳过区 / 土层条）

**Files:**
- Modify: `vole-macos/Clean/CleanCandidatesView.swift`
- Test: `vole-macosTests/CleanCandidatesViewTests.swift`

**Interfaces:**
- Consumes: `CleanSession.entries` / `selectedIDs`、`ByteFormat`、`PathAuthorization.requiresPrivilegedHelper`、`SoilPanel`
- Produces: `func selectedTotalBytes(entries: [VolePlanEntry], selectedIDs: Set<String>) -> UInt64`（供测试与视图共用）

- [ ] **Step 1: Write the failing test**

```swift
func test_selectedTotalBytesSumsSelectedOnly() {
    let a = VolePlanEntry(id: "a", path: "/a", label: "A", size: 100, ruleID: "r", skipReason: nil, dev: 0, ino: 0, mtime: 0)
    let b = VolePlanEntry(id: "b", path: "/b", label: "B", size: 50, ruleID: "r", skipReason: nil, dev: 0, ino: 0, mtime: 0)
    XCTAssertEqual(selectedTotalBytes(entries: [a, b], selectedIDs: ["a"]), 100)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme vole-macos -only-testing:vole-macosTests/CleanCandidatesViewTests -destination 'platform=macOS'`
Expected: FAIL

- [ ] **Step 3: Write minimal implementation**

顶部：标题 `挑要清掉的` + `全选/全不选`；`SoilPanel(fraction: Double(selectedTotalBytes)/Double(totalBytes))` + `已选 N · 共 M`。列表行：勾选 + label + 路径（monospace 截断）+ 体积；系统路径行内 `需助手`（Soil）。底部「跳过」区折叠 + 原因；助手未就绪提示「将跳过」。确认对话框沿用现有文案。

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme vole-macos -only-testing:vole-macosTests/CleanCandidatesViewTests -destination 'platform=macOS'`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add vole-macos/Clean/CleanCandidatesView.swift vole-macosTests/CleanCandidatesViewTests.swift
git commit -m "feat: restyle candidates with strata, helper flag, skip section"
```

---

### Task 6: 清理中 / 结果（含已回收体积）

**Files:**
- Modify: `vole-macos/Clean/CleanApplyingView.swift`、`vole-macos/Clean/CleanResultView.swift`
- Test: `vole-macosTests/CleanResultViewTests.swift`

**Interfaces:**
- Consumes: `SoilPanel`、`VoleReport`
- Produces: `func recoveredBytes(_ report: VoleReport) -> UInt64`（`trashedBytes + deletedBytes`）

- [ ] **Step 1: Write the failing test**

```swift
func test_recoveredBytesSumsTrashAndDeleted() {
    let r = VoleReport(succeeded: 1, skipped: 0, failed: 0, skippedByReason: [], trashedBytes: 100, deletedBytes: 50, coverageNote: nil)
    XCTAssertEqual(recoveredBytes(r), 150)
}
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL

- [ ] **Step 3: Write minimal implementation**

清理中：`SoilPanel(fraction: progress)`（progress 由 `progressScanned` 与选中数估算；若无总量则用 indeterminate 视觉 = 呼吸土层条），注明「取消可能部分清理」+ `取消`。结果：吉祥物 + `SoilPanel(fraction: 1)` + `已回收 \(ByteFormat.string(recoveredBytes(report)))` + 摘要（成功/助手未就绪跳过/失败）+ `完成`（`keyboardShortcut(.defaultAction)`）。

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme vole-macos -only-testing:vole-macosTests/CleanResultViewTests -destination 'platform=macOS'`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add vole-macos/Clean/CleanApplyingView.swift vole-macos/Clean/CleanResultView.swift vole-macosTests/CleanResultViewTests.swift
git commit -m "feat: restyle applying and result with recovered strata"
```

---

### Task 7: Accessibility & 深色模式打磨

**Files:**
- Modify: `vole-macos/Design/SoilStrataView.swift`（accessibility label 已含，补深色对比）、`vole-macos/Clean/CleanCandidatesView.swift`（焦点环）、`vole-macos/Shell/SidebarView.swift`（VoiceOver label）
- Test: `vole-macosTests/VoleThemeTests.swift`（补深色 token 存在性断言）

- [ ] **Step 1: Write the failing test**

断言 `VoleTheme.contentBackground` 在 dark appearance 返回非 nil（或拆为 `contentBackgroundDark` 常量断言 hex）。

- [ ] **Step 2: Run test to verify it fails** → Expected: FAIL

- [ ] **Step 3: Write minimal implementation**

补深色 token；确认 Reduce Motion 下土层条无呼吸；按钮/行 `.focusable()` 与 `accessibilityLabel`；侧栏田鼠 `accessibilityLabel("Vole 标志")`。

- [ ] **Step 4: Run test to verify it passes** → Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add vole-macos vole-macosTests
git commit -m "feat: polish accessibility and dark mode for vole ui"
```

---

### Task 8: 全量回归 + 验收清单

- [ ] **Step 1:** `xcodebuild test -scheme vole-macos -destination 'platform=macOS'`（全绿）
- [ ] **Step 2:** 人工核对 spec §11 验收清单（浅/深、土层条三态、需助手跳过、结果摘要、Reduce Motion、FDA 提示）
- [ ] **Step 3: Commit（如需）**

```bash
git add -A
git commit -m "chore: verify vole ui shell + clean acceptance"
```
