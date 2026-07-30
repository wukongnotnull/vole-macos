# Vole macOS Desktop Clean MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use wukong-code:subagent-driven-development (recommended) or wukong-code:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 `vole-macos` 交付本机可跑的 SwiftUI 原型：内嵌 `vole` sidecar，完成 `clean` 的 plan → 勾选 → apply（默认废纸篓）。

**Architecture:** SwiftUI 薄壳通过 `Process` 调用 Bundle 内 `vole`。`--json-stream` 只做进度与预览；权威 Plan 来自 `--plan-out`；勾选后过滤 `entries`（保留 `dev/ino/mtime` 等全部字段）再 `--apply --json-stream`。关闭 App Sandbox / Hardened Runtime / User Script Sandboxing。

**Tech Stack:** SwiftUI、Swift Testing、Foundation `Process`、兄弟仓 `../vole`（`cargo build -p vole-cli --release`）、冻结协议 `schema_version = 1`。

**Design:** [`../specs/2026-07-30-2328-desktop-clean-mvp-design.md`](../specs/2026-07-30-2328-desktop-clean-mvp-design.md)

## Global Constraints

- 许可证：GPL-3.0-only（与 CLI 一致）。
- 平台：仅 macOS；本里程碑不上 MAS、不做 Developer ID / 公证。
- MVP 仅 `clean`；不做 `status` / `uninstall` / `optimize` / `history` / `--permanent`。
- 零改 `vole` 仓（除非发现阻塞级 bug，另开 PR）。
- 权威 Plan 必须来自 `--plan-out`；禁止从 `candidate` 事件重建 apply plan。
- Bundle 布局：`Contents/MacOS/vole` + `Contents/share/vole/rules/`；失败回退 `VOLE_RULES_DIR`。
- 退出码：`0` 成功、`130` 用户取消、`1` 错误。
- 每个 Task 至少一次 commit；合并前人工验收清单过关。
- Bundle ID：`cn.waytoai.vole-macos`（Xcode 模板已设）。
- 默认 `VOLE_SRC=$(SRCROOT)/../vole`。

---

## File Structure

```
LICENSE                                    # GPL-3.0（已从 vole 拷贝，Task 1 纳入版本库）
README.md                                  # 前置条件、并列仓路径、如何 Run
scripts/embed-vole.sh                      # Xcode Run Script 调用

vole-macos/
  vole_macosApp.swift                      # @main；注入 CleanSession
  ContentView.swift                        # 根视图 → CleanRootView
  Sidecar/
    VoleProtocol.swift                     # Plan / Report / StreamEvent Codable
    PlanIO.swift                           # 读写 plan、过滤 entries、TTL
    SidecarRunner.swift                    # Process 封装、退出码、取消
  Clean/
    CleanSession.swift                     # 五态状态机 / ViewModel
    CleanRootView.swift                    # 按 phase 切换子视图
    CleanIdleView.swift
    CleanScanningView.swift
    CleanCandidatesView.swift
    CleanApplyingView.swift
    CleanResultView.swift
  Support/
    ByteFormat.swift                       # 人类可读字节
    FDAProbe.swift                         # 主动探测 + 打开设置

vole-macosTests/
  VoleProtocolTests.swift
  PlanIOTests.swift
  ByteFormatTests.swift
  FDAProbeTests.swift                      # 纯逻辑（URL / 探测路径常量）

vole-macos.xcodeproj/project.pbxproj       # 关沙盒 + 加 Run Script Phase
```

Xcode 使用 `PBXFileSystemSynchronizedRootGroup`：`vole-macos/` 与 `vole-macosTests/` 下新增 `.swift` 会自动进 target，**不必**手改 pbxproj 的文件引用。只需改 Build Settings 与 Build Phases。

---

### Task 1: 工程基线（LICENSE / README / 关沙盒 / 纳入 Xcode 脚手架）

**Files:**
- Create: `LICENSE`（若尚未入库：从 `../vole/LICENSE` 复制）
- Modify: `README.md`
- Modify: `vole-macos.xcodeproj/project.pbxproj`（三处沙盒相关开关）
- Add (untracked → tracked): `vole-macos/**`, `vole-macosTests/**`, `vole-macosUITests/**`, `vole-macos.xcodeproj/**`

**Interfaces:**
- Consumes: 无
- Produces: 可编译、无 App Sandbox 的空壳 App；后续 Task 可放心 spawn 子进程

- [ ] **Step 1: 确认 LICENSE 存在**

```bash
test -f /Users/wukong/Documents/vole-macos/LICENSE && head -1 /Users/wukong/Documents/vole-macos/LICENSE
```

Expected: 含 `GNU GENERAL PUBLIC LICENSE`。若缺失：

```bash
cp /Users/wukong/Documents/vole/LICENSE /Users/wukong/Documents/vole-macos/LICENSE
```

- [ ] **Step 2: 写 README**

将 `README.md` 替换为：

```markdown
# vole-macos

Vole 的 macOS SwiftUI 桌面端（GPL-3.0）。本里程碑：内嵌 `vole` sidecar，提供 `clean` 的 plan → 勾选 → apply（默认废纸篓）。

## 前置

- macOS + Xcode（工程模板部署目标以 `.xcodeproj` 为准）
- Rust toolchain（与兄弟仓 `vole` 的 `rust-toolchain.toml` 一致）
- 兄弟仓：本仓与 `vole` 并列，例如：

```text
Documents/vole
Documents/vole-macos
```

可用环境变量 `VOLE_SRC` 覆盖默认路径 `$(SRCROOT)/../vole`。

## 运行

1. 用 Xcode 打开 `vole-macos.xcodeproj`
2. 确认 Build Settings：`ENABLE_APP_SANDBOX=NO`、`ENABLE_HARDENED_RUNTIME=NO`、`ENABLE_USER_SCRIPT_SANDBOXING=NO`
3. Product → Run（首次会 `cargo build -p vole-cli --release`，较慢）
4. 若清理扫描结果异常少：系统设置 → 隐私与安全性 → 完全磁盘访问，勾选 **vole-macos**

## 设计

见 [`docs/wukong-code/specs/2026-07-30-2328-desktop-clean-mvp-design.md`](docs/wukong-code/specs/2026-07-30-2328-desktop-clean-mvp-design.md)。
```

- [ ] **Step 3: 关闭沙盒相关 Build Settings**

在 `vole-macos.xcodeproj/project.pbxproj` 中：

1. 所有出现的 `ENABLE_APP_SANDBOX = YES;` → `ENABLE_APP_SANDBOX = NO;`（Debug + Release，应用 target）
2. 所有出现的 `ENABLE_HARDENED_RUNTIME = YES;` → `ENABLE_HARDENED_RUNTIME = NO;`
3. 所有出现的 `ENABLE_USER_SCRIPT_SANDBOXING = YES;` → `ENABLE_USER_SCRIPT_SANDBOXING = NO;`（项目级 Debug + Release）

用 rg 自检：

```bash
cd /Users/wukong/Documents/vole-macos
rg 'ENABLE_APP_SANDBOX|ENABLE_HARDENED_RUNTIME|ENABLE_USER_SCRIPT_SANDBOXING' vole-macos.xcodeproj/project.pbxproj
```

Expected: 三值均为 `NO`，无残留 `YES`。

- [ ] **Step 4: 验证 Xcode 能编译空壳**

```bash
cd /Users/wukong/Documents/vole-macos
xcodebuild -scheme vole-macos -configuration Debug -destination 'platform=macOS' build 2>&1 | tail -20
```

Expected: `BUILD SUCCEEDED`。

- [ ] **Step 5: Commit**

```bash
cd /Users/wukong/Documents/vole-macos
git add LICENSE README.md vole-macos.xcodeproj vole-macos vole-macosTests vole-macosUITests
git commit -m "$(cat <<'EOF'
chore: scaffold macOS app with sandbox disabled

Track the Xcode template and turn off App Sandbox / Hardened Runtime /
User Script Sandboxing so the upcoming vole sidecar can access ~/Library.
EOF
)"
```

---

### Task 2: 嵌入脚本 `embed-vole.sh` + Xcode Run Script Phase

**Files:**
- Create: `scripts/embed-vole.sh`
- Modify: `vole-macos.xcodeproj/project.pbxproj`（在 Sources 之前插入 `PBXShellScriptBuildPhase`）

**Interfaces:**
- Consumes: `VOLE_SRC` 或默认 `$(SRCROOT)/../vole`；`TARGET_BUILD_DIR` / `CONTENTS_FOLDER_PATH`（Xcode 注入）
- Produces: Bundle 内 `Contents/MacOS/vole` 与 `Contents/share/vole/rules/*.toml`

- [ ] **Step 1: 写嵌入脚本**

创建 `scripts/embed-vole.sh`：

```bash
#!/usr/bin/env bash
set -euo pipefail

SRCROOT="${SRCROOT:?SRCROOT required}"
TARGET_BUILD_DIR="${TARGET_BUILD_DIR:?TARGET_BUILD_DIR required}"
CONTENTS_FOLDER_PATH="${CONTENTS_FOLDER_PATH:?CONTENTS_FOLDER_PATH required}"

VOLE_SRC="${VOLE_SRC:-$SRCROOT/../vole}"
CONTENTS="$TARGET_BUILD_DIR/$CONTENTS_FOLDER_PATH"
MACOS_DIR="$CONTENTS/MacOS"
RULES_DST="$CONTENTS/share/vole/rules"

if [[ ! -d "$VOLE_SRC/crates/vole-cli" ]]; then
  echo "error: vole source not found at: $VOLE_SRC" >&2
  echo "hint: clone vole next to vole-macos, or set VOLE_SRC" >&2
  exit 1
fi

if ! command -v cargo >/dev/null 2>&1; then
  echo "error: cargo not found in PATH" >&2
  exit 1
fi

echo "note: building vole-cli --release from $VOLE_SRC"
(
  cd "$VOLE_SRC"
  cargo build -p vole-cli --release
)

VOLE_BIN="$VOLE_SRC/target/release/vole"
if [[ ! -x "$VOLE_BIN" ]]; then
  echo "error: expected executable at $VOLE_BIN" >&2
  exit 1
fi

mkdir -p "$MACOS_DIR" "$RULES_DST"
cp -f "$VOLE_BIN" "$MACOS_DIR/vole"
chmod 755 "$MACOS_DIR/vole"

shopt -s nullglob
RULES=( "$VOLE_SRC/data/rules/"*.toml )
if (( ${#RULES[@]} == 0 )); then
  echo "error: no rules toml under $VOLE_SRC/data/rules" >&2
  exit 1
fi
rsync -a --delete "$VOLE_SRC/data/rules/" "$RULES_DST/"

echo "note: embedded vole → $MACOS_DIR/vole"
echo "note: embedded rules → $RULES_DST ($(ls -1 "$RULES_DST" | wc -l | tr -d ' ') files)"
```

```bash
chmod +x /Users/wukong/Documents/vole-macos/scripts/embed-vole.sh
```

- [ ] **Step 2: 在 pbxproj 加入 Shell Script Build Phase**

在 `project.pbxproj` 的 `/* Begin PBXShellScriptBuildPhase section */` 处新增（若尚无该 section，在 `objects = {` 内插入完整 section）。使用固定 ID（避免与现有 `67FB4F*` 冲突）：

```
/* Begin PBXShellScriptBuildPhase section */
		A1EMBED001301BA00200E0AFC2 /* Embed vole sidecar */ = {
			isa = PBXShellScriptBuildPhase;
			alwaysOutOfDate = 1;
			buildActionMask = 2147483647;
			files = (
			);
			inputFileListPaths = (
			);
			inputPaths = (
			);
			name = "Embed vole sidecar";
			outputFileListPaths = (
			);
			outputPaths = (
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/bash;
			shellScript = "\"${SRCROOT}/scripts/embed-vole.sh\"\n";
		};
/* End PBXShellScriptBuildPhase section */
```

在应用 target `67FB4F88301BA00000E0AFC2 /* vole-macos */` 的 `buildPhases = (` 中，把 `A1EMBED001301BA00200E0AFC2 /* Embed vole sidecar */,` **插到** Sources 那一行**之前**（先嵌入再编译签名更稳；至少须在 Copy Bundle Resources 之前完成）。

- [ ] **Step 3: 构建并验证 Bundle 内容**

```bash
cd /Users/wukong/Documents/vole-macos
xcodebuild -scheme vole-macos -configuration Debug -destination 'platform=macOS' build 2>&1 | tee /tmp/vole-macos-build.log | tail -40
APP=$(find ~/Library/Developer/Xcode/DerivedData -name 'vole-macos.app' -path '*Build/Products/Debug/*' 2>/dev/null | head -1)
echo "APP=$APP"
test -x "$APP/Contents/MacOS/vole"
ls "$APP/Contents/share/vole/rules" | head
"$APP/Contents/MacOS/vole" --version
```

Expected: `BUILD SUCCEEDED`；`vole --version` 打印版本；rules 目录非空。

- [ ] **Step 4: Commit**

```bash
git add scripts/embed-vole.sh vole-macos.xcodeproj/project.pbxproj
git commit -m "$(cat <<'EOF'
build: embed vole sidecar and rules into app bundle

Add a Run Script that cargo-builds sibling ../vole and copies the binary
plus data/rules into Contents/MacOS and Contents/share/vole/rules.
EOF
)"
```

---

### Task 3: 协议模型 + NDJSON 解码（TDD）

**Files:**
- Create: `vole-macos/Sidecar/VoleProtocol.swift`
- Create: `vole-macosTests/VoleProtocolTests.swift`
- Modify: `vole-macosTests/vole_macosTests.swift`（删除空 `example` 测试，或保留无关紧要）

**Interfaces:**
- Consumes: 冻结 JSON 形状（见 `vole` 仓 `docs/protocol.md` / `vole-proto`）
- Produces:
  - `struct VolePlan: Codable`（`schemaVersion`, `createdAt`, `ttlSecs`, `entries`, `coverageNote?`）
  - `struct VolePlanEntry: Codable`
  - `enum VoleStreamEvent: Codable`（`progress` / `candidate` / `skipped` / `done` / `aborted`）
  - `struct VoleReport: Codable`
  - `static func decodeNDJSONLine(_ line: String) throws -> VoleStreamEvent`

- [ ] **Step 1: 写失败测试**

创建 `vole-macosTests/VoleProtocolTests.swift`：

```swift
import Foundation
import Testing
@testable import vole_macos

struct VoleProtocolTests {
    @Test func decodesProgressLine() throws {
        let line = #"{"schema_version":1,"type":"progress","scanned":128,"current":"~/Library/Caches"}"#
        let event = try VoleStreamEvent.decodeNDJSONLine(line)
        guard case let .progress(scanned, current) = event else {
            Issue.record("expected progress")
            return
        }
        #expect(scanned == 128)
        #expect(current == "~/Library/Caches")
    }

    @Test func decodesCandidateLine() throws {
        let line = #"{"schema_version":1,"type":"candidate","id":"c-1","path":"/tmp/a","label":"A","size":1024,"rule_id":"chrome-cache"}"#
        let event = try VoleStreamEvent.decodeNDJSONLine(line)
        guard case let .candidate(id, path, label, size, ruleID) = event else {
            Issue.record("expected candidate")
            return
        }
        #expect(id == "c-1")
        #expect(path == "/tmp/a")
        #expect(label == "A")
        #expect(size == 1024)
        #expect(ruleID == "chrome-cache")
    }

    @Test func planRoundTripPreservesIdentityFields() throws {
        let json = """
        {
          "schema_version": 1,
          "created_at": 1700000000,
          "ttl_secs": 900,
          "coverage_note": "note",
          "entries": [
            {
              "id": "chrome-cache-0",
              "path": "/Users/test/Library/Caches/Google",
              "label": "Chrome cache",
              "size": 1024,
              "rule_id": "chrome-cache",
              "skip_reason": null,
              "dev": 17,
              "ino": 42,
              "mtime": 1700000001
            }
          ]
        }
        """
        let data = Data(json.utf8)
        let plan = try JSONDecoder().decode(VolePlan.self, from: data)
        #expect(plan.schemaVersion == 1)
        #expect(plan.entries.count == 1)
        #expect(plan.entries[0].dev == 17)
        #expect(plan.entries[0].ino == 42)
        let encoded = try JSONEncoder().encode(plan)
        let again = try JSONDecoder().decode(VolePlan.self, from: encoded)
        #expect(again.entries[0].dev == 17)
        #expect(again.entries[0].mtime == 1700000001)
    }
}
```

- [ ] **Step 2: 跑测试确认失败**

```bash
cd /Users/wukong/Documents/vole-macos
xcodebuild test -scheme vole-macos -destination 'platform=macOS' -only-testing:vole-macosTests/VoleProtocolTests 2>&1 | tail -30
```

Expected: FAIL（`VoleStreamEvent` / `VolePlan` 未定义）。

- [ ] **Step 3: 最小实现**

创建 `vole-macos/Sidecar/VoleProtocol.swift`：

```swift
import Foundation

struct VolePlan: Codable, Equatable {
    var schemaVersion: UInt32
    var createdAt: UInt64
    var ttlSecs: UInt64
    var entries: [VolePlanEntry]
    var coverageNote: String?

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case createdAt = "created_at"
        case ttlSecs = "ttl_secs"
        case entries
        case coverageNote = "coverage_note"
    }
}

struct VolePlanEntry: Codable, Equatable, Identifiable {
    var id: String
    var path: String
    var label: String
    var size: UInt64
    var ruleID: String
    var skipReason: String?
    var dev: UInt64
    var ino: UInt64
    var mtime: UInt64

    enum CodingKeys: String, CodingKey {
        case id, path, label, size
        case ruleID = "rule_id"
        case skipReason = "skip_reason"
        case dev, ino, mtime
    }
}

struct VoleReport: Codable, Equatable {
    var succeeded: UInt64
    var skipped: UInt64
    var failed: UInt64
    var skippedByReason: [VoleSkipSummary]
    var trashedBytes: UInt64
    var deletedBytes: UInt64
    var coverageNote: String?

    enum CodingKeys: String, CodingKey {
        case succeeded, skipped, failed
        case skippedByReason = "skipped_by_reason"
        case trashedBytes = "trashed_bytes"
        case deletedBytes = "deleted_bytes"
        case coverageNote = "coverage_note"
    }
}

struct VoleSkipSummary: Codable, Equatable {
    var reason: String
    var count: UInt64
    var ruleIDs: [String]

    enum CodingKeys: String, CodingKey {
        case reason, count
        case ruleIDs = "rule_ids"
    }
}

enum VoleStreamEvent: Equatable {
    case progress(scanned: UInt64, current: String)
    case candidate(id: String, path: String, label: String, size: UInt64, ruleID: String)
    case skipped(ruleID: String, reason: String)
    case done(report: VoleReport)
    case aborted(reason: String)

    static func decodeNDJSONLine(_ line: String) throws -> VoleStreamEvent {
        let data = Data(line.utf8)
        let raw = try JSONDecoder().decode(RawStreamEvent.self, from: data)
        switch raw.type {
        case "progress":
            return .progress(scanned: raw.scanned ?? 0, current: raw.current ?? "")
        case "candidate":
            return .candidate(
                id: raw.id ?? "",
                path: raw.path ?? "",
                label: raw.label ?? "",
                size: raw.size ?? 0,
                ruleID: raw.ruleID ?? ""
            )
        case "skipped":
            return .skipped(ruleID: raw.ruleID ?? "", reason: raw.reason ?? "")
        case "done":
            guard let report = raw.report else {
                throw VoleProtocolError.missingReport
            }
            return .done(report: report)
        case "aborted":
            return .aborted(reason: raw.reason ?? "")
        default:
            throw VoleProtocolError.unknownType(raw.type)
        }
    }
}

enum VoleProtocolError: Error {
    case missingReport
    case unknownType(String)
}

private struct RawStreamEvent: Decodable {
    var type: String
    var scanned: UInt64?
    var current: String?
    var id: String?
    var path: String?
    var label: String?
    var size: UInt64?
    var ruleID: String?
    var reason: String?
    var report: VoleReport?

    enum CodingKeys: String, CodingKey {
        case type, scanned, current, id, path, label, size, reason, report
        case ruleID = "rule_id"
    }
}
```

- [ ] **Step 4: 跑测试确认通过**

```bash
xcodebuild test -scheme vole-macos -destination 'platform=macOS' -only-testing:vole-macosTests/VoleProtocolTests 2>&1 | tail -20
```

Expected: 全部 PASS。

- [ ] **Step 5: Commit**

```bash
git add vole-macos/Sidecar/VoleProtocol.swift vole-macosTests/VoleProtocolTests.swift
git commit -m "$(cat <<'EOF'
feat: add Codable models for vole plan and NDJSON events

Decode frozen schema_version=1 stream lines and round-trip plan identity
fields needed for apply TOCTOU checks.
EOF
)"
```

---

### Task 4: PlanIO（过滤子集 + TTL）（TDD）

**Files:**
- Create: `vole-macos/Sidecar/PlanIO.swift`
- Create: `vole-macosTests/PlanIOTests.swift`

**Interfaces:**
- Consumes: `VolePlan` / `VolePlanEntry`
- Produces:
  - `enum PlanIO`
  - `static func filter(plan:selectedIDs:) -> VolePlan`
  - `static func isExpired(_ plan:now:) -> Bool`
  - `static func write(_ plan:to:) throws`
  - `static func read(from:) throws -> VolePlan`
  - `static func cachesDirectory() throws -> URL`

- [ ] **Step 1: 写失败测试**

```swift
import Foundation
import Testing
@testable import vole_macos

struct PlanIOTests {
    private func samplePlan() -> VolePlan {
        VolePlan(
            schemaVersion: 1,
            createdAt: 1_700_000_000,
            ttlSecs: 900,
            entries: [
                VolePlanEntry(
                    id: "a", path: "/tmp/a", label: "A", size: 1,
                    ruleID: "r", skipReason: nil, dev: 1, ino: 2, mtime: 3
                ),
                VolePlanEntry(
                    id: "b", path: "/tmp/b", label: "B", size: 2,
                    ruleID: "r", skipReason: "whitelisted", dev: 1, ino: 3, mtime: 3
                ),
            ],
            coverageNote: "n"
        )
    }

    @Test func filterKeepsSelectedEntriesAndMetadata() {
        let filtered = PlanIO.filter(plan: samplePlan(), selectedIDs: Set(["a"]))
        #expect(filtered.entries.map(\.id) == ["a"])
        #expect(filtered.createdAt == 1_700_000_000)
        #expect(filtered.ttlSecs == 900)
        #expect(filtered.entries[0].dev == 1)
        #expect(filtered.entries[0].ino == 2)
    }

    @Test func expiredWhenPastTTL() {
        let plan = samplePlan()
        let now = Date(timeIntervalSince1970: TimeInterval(plan.createdAt + plan.ttlSecs + 1))
        #expect(PlanIO.isExpired(plan, now: now))
        let fresh = Date(timeIntervalSince1970: TimeInterval(plan.createdAt + 10))
        #expect(!PlanIO.isExpired(plan, now: fresh))
    }

    @Test func writeReadRoundTrip() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("vole-planio-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let url = dir.appendingPathComponent("plan.json")
        try PlanIO.write(samplePlan(), to: url)
        let loaded = try PlanIO.read(from: url)
        #expect(loaded.entries.count == 2)
        #expect(loaded.entries[0].mtime == 3)
    }
}
```

- [ ] **Step 2: 跑测试确认失败**

```bash
xcodebuild test -scheme vole-macos -destination 'platform=macOS' -only-testing:vole-macosTests/PlanIOTests 2>&1 | tail -20
```

Expected: FAIL（`PlanIO` 未定义）。

- [ ] **Step 3: 最小实现**

```swift
import Foundation

enum PlanIO {
    static func filter(plan: VolePlan, selectedIDs: Set<String>) -> VolePlan {
        var copy = plan
        copy.entries = plan.entries.filter { selectedIDs.contains($0.id) }
        return copy
    }

    static func isExpired(_ plan: VolePlan, now: Date = Date()) -> Bool {
        let expiry = Date(timeIntervalSince1970: TimeInterval(plan.createdAt + plan.ttlSecs))
        return now >= expiry
    }

    static func write(_ plan: VolePlan, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(plan)
        try data.write(to: url, options: .atomic)
    }

    static func read(from url: URL) throws -> VolePlan {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(VolePlan.self, from: data)
    }

    static func cachesDirectory() throws -> URL {
        let base = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = base.appendingPathComponent("cn.waytoai.vole-macos", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
```

- [ ] **Step 4: 跑测试确认通过**

```bash
xcodebuild test -scheme vole-macos -destination 'platform=macOS' -only-testing:vole-macosTests/PlanIOTests 2>&1 | tail -20
```

Expected: PASS。

- [ ] **Step 5: Commit**

```bash
git add vole-macos/Sidecar/PlanIO.swift vole-macosTests/PlanIOTests.swift
git commit -m "$(cat <<'EOF'
feat: add plan filter, TTL check, and cache-file IO

Keep selected entries with full identity fields so apply can re-validate
dev/ino/mtime without rebuilding from stream events.
EOF
)"
```

---

### Task 5: SidecarRunner（Process + 退出码）（TDD）

**Files:**
- Create: `vole-macos/Sidecar/SidecarRunner.swift`
- Create: `vole-macosTests/SidecarRunnerTests.swift`

**Interfaces:**
- Consumes: Bundle 内 `vole` 路径；`PlanIO.cachesDirectory`
- Produces:
  - `enum SidecarExit: Equatable { case success; case cancelled; case failed(message: String) }`
  - `enum SidecarRunner`
  - `static func bundledVoleURL() -> URL?`
  - `static func mapExitCode(_ code: Int32, stderr: String) -> SidecarExit`
  - `actor VoleProcess`（可启动 plan/apply、异步读 stdout 行、`cancel()`）

说明：真实 `Process` 集成在本 Task 用**映射函数单测** + 手动 smoke；完整 plan 流程在 Task 7 接上。

- [ ] **Step 1: 写失败测试**

```swift
import Testing
@testable import vole_macos

struct SidecarRunnerTests {
    @Test func mapsExitCodes() {
        #expect(SidecarRunner.mapExitCode(0, stderr: "") == .success)
        #expect(SidecarRunner.mapExitCode(130, stderr: "cancelled") == .cancelled)
        let failed = SidecarRunner.mapExitCode(1, stderr: "另一个 vole clean 正在运行")
        guard case let .failed(message) = failed else {
            Issue.record("expected failed")
            return
        }
        #expect(message.contains("正在运行"))
    }
}
```

- [ ] **Step 2: 跑测试确认失败**

```bash
xcodebuild test -scheme vole-macos -destination 'platform=macOS' -only-testing:vole-macosTests/SidecarRunnerTests 2>&1 | tail -20
```

Expected: FAIL。

- [ ] **Step 3: 实现 Runner**

```swift
import Foundation

enum SidecarExit: Equatable {
    case success
    case cancelled
    case failed(message: String)
}

enum SidecarRunner {
    static func bundledVoleURL() -> URL? {
        Bundle.main.url(forAuxiliaryExecutable: "vole")
            ?? Bundle.main.bundleURL
                .appendingPathComponent("Contents/MacOS/vole")
    }

    static func mapExitCode(_ code: Int32, stderr: String) -> SidecarExit {
        switch code {
        case 0: return .success
        case 130: return .cancelled
        default:
            let trimmed = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            return .failed(message: trimmed.isEmpty ? "vole exited with code \(code)" : trimmed)
        }
    }

    static func rulesEnvironment() -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        if let rules = Bundle.main.bundleURL
            .appendingPathComponent("Contents/share/vole/rules").path as String?,
           FileManager.default.fileExists(atPath: rules) {
            env["VOLE_RULES_DIR"] = rules
        }
        // Prefer relative discovery; VOLE_RULES_DIR is fallback when layout differs.
        let relative = Bundle.main.bundleURL
            .appendingPathComponent("Contents/share/vole/rules").path
        if FileManager.default.fileExists(atPath: relative) {
            env["VOLE_RULES_DIR"] = relative
        }
        return env
    }
}

actor VoleProcess {
    private var process: Process?
    private var stdoutTask: Task<Void, Never>?
    private var stderrData = Data()

    func run(
        arguments: [String],
        onStdoutLine: @escaping @Sendable (String) -> Void
    ) async -> SidecarExit {
        guard let vole = SidecarRunner.bundledVoleURL() else {
            return .failed(message: "embedded vole binary missing; rebuild the app")
        }

        let proc = Process()
        proc.executableURL = vole
        proc.arguments = arguments
        proc.environment = SidecarRunner.rulesEnvironment()
        proc.currentDirectoryURL = vole.deletingLastPathComponent()

        let outPipe = Pipe()
        let errPipe = Pipe()
        proc.standardOutput = outPipe
        proc.standardError = errPipe
        proc.standardInput = FileHandle.nullDevice

        self.process = proc
        self.stderrData = Data()

        do {
            try proc.run()
        } catch {
            return .failed(message: error.localizedDescription)
        }

        stdoutTask = Task {
            let handle = outPipe.fileHandleForReading
            var buffer = Data()
            while true {
                let chunk = handle.availableData
                if chunk.isEmpty { break }
                buffer.append(chunk)
                while let range = buffer.range(of: Data([0x0A])) {
                    let lineData = buffer.subdata(in: buffer.startIndex..<range.lowerBound)
                    buffer.removeSubrange(buffer.startIndex...range.lowerBound)
                    if let line = String(data: lineData, encoding: .utf8), !line.isEmpty {
                        onStdoutLine(line)
                    }
                }
            }
        }

        // Drain stderr concurrently
        let errHandle = errPipe.fileHandleForReading
        while proc.isRunning {
            let chunk = errHandle.availableData
            if !chunk.isEmpty { stderrData.append(chunk) }
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        let rest = errHandle.availableData
        if !rest.isEmpty { stderrData.append(rest) }

        await stdoutTask?.value
        let code = proc.terminationStatus
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""
        return SidecarRunner.mapExitCode(code, stderr: stderr)
    }

    func cancel() {
        process?.terminate()
    }
}
```

注意：`rulesEnvironment` 里不要写无效 optional 绑定；实现时保持：

```swift
static func rulesEnvironment() -> [String: String] {
    var env = ProcessInfo.processInfo.environment
    let relative = Bundle.main.bundleURL
        .appendingPathComponent("Contents/share/vole/rules").path
    if FileManager.default.fileExists(atPath: relative) {
        env["VOLE_RULES_DIR"] = relative
    }
    return env
}
```

（上面长块中若有重复/笔误，以本精简版为准。）

- [ ] **Step 4: 跑测试确认通过**

```bash
xcodebuild test -scheme vole-macos -destination 'platform=macOS' -only-testing:vole-macosTests/SidecarRunnerTests 2>&1 | tail -20
```

Expected: PASS。

- [ ] **Step 5: Commit**

```bash
git add vole-macos/Sidecar/SidecarRunner.swift vole-macosTests/SidecarRunnerTests.swift
git commit -m "$(cat <<'EOF'
feat: add Process-based vole sidecar runner

Map exit codes 0/130/1 and stream stdout lines for NDJSON consumers.
EOF
)"
```

---

### Task 6: FDA 探测 + 打开设置 + 字节格式化（TDD）

**Files:**
- Create: `vole-macos/Support/FDAProbe.swift`
- Create: `vole-macos/Support/ByteFormat.swift`
- Create: `vole-macosTests/SupportHelpersTests.swift`

**Interfaces:**
- Produces:
  - `enum FDAProbe { static var probePath: String; static func looksDenied() -> Bool; static var settingsURL: URL }`
  - `enum ByteFormat { static func string(_ bytes: UInt64) -> String }`

- [ ] **Step 1: 写失败测试**

```swift
import Foundation
import Testing
@testable import vole_macos

struct SupportHelpersTests {
    @Test func settingsURLIsPrivacyFDA() {
        #expect(FDAProbe.settingsURL.absoluteString.contains("Privacy_AllFiles")
            || FDAProbe.settingsURL.absoluteString.contains("Privacy_FullDiskAccess")
            || FDAProbe.settingsURL.scheme == "x-apple.systempreferences")
    }

    @Test func byteFormatUsesBinaryUnits() {
        #expect(ByteFormat.string(0) == "0 B")
        #expect(ByteFormat.string(1024) == "1 KB")
        #expect(ByteFormat.string(1_048_576) == "1 MB")
    }
}
```

- [ ] **Step 2: 跑测试确认失败** → 然后实现：

```swift
import Foundation
import AppKit

enum FDAProbe {
    /// Known TCC-protected path; listing often fails without Full Disk Access.
    static let probePath = NSHomeDirectory() + "/Library/Mail"

    static var settingsURL: URL {
        // macOS Ventura+ style deep link; falls back still opens System Settings.
        URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
    }

    static func looksDenied() -> Bool {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: probePath, isDirectory: &isDir) else {
            // Path missing on some machines — do not false-alarm.
            return false
        }
        do {
            _ = try fm.contentsOfDirectory(atPath: probePath)
            return false
        } catch {
            return true
        }
    }

    static func openSettings() {
        NSWorkspace.shared.open(settingsURL)
    }
}
```

```swift
import Foundation

enum ByteFormat {
    static func string(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .binary
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: Int64(clamping: bytes))
    }
}
```

若 `ByteCountFormatter` 输出带窄空格或本地化差异，把测试改为：

```swift
#expect(ByteFormat.string(1024).contains("1"))
#expect(ByteFormat.string(1024).uppercased().contains("K"))
```

- [ ] **Step 3: 测试通过后 Commit**

```bash
git add vole-macos/Support vole-macosTests/SupportHelpersTests.swift
git commit -m "$(cat <<'EOF'
feat: add FDA probe helper and binary byte formatting

Actively detect missing Full Disk Access instead of relying on vole
nonzero exits, which often silently under-scan.
EOF
)"
```

---

### Task 7: CleanSession 五态状态机

**Files:**
- Create: `vole-macos/Clean/CleanSession.swift`

**Interfaces:**
- Consumes: `VoleProcess`, `PlanIO`, `VoleStreamEvent`, `FDAProbe`
- Produces: `@MainActor final class CleanSession: ObservableObject` with:
  - `enum Phase { idle, scanning, candidates, applying, result }`
  - `@Published var phase`, `progressScanned`, `progressCurrent`, `entries`, `selectedIDs`, `report`, `errorMessage`, `showFDAAlert`, `voleVersion`
  - `func refreshVersion()`, `func startScan()`, `func cancel()`, `func applySelected()`, `func reset()`

- [ ] **Step 1: 实现 CleanSession**

```swift
import Foundation
import Combine

@MainActor
final class CleanSession: ObservableObject {
    enum Phase: Equatable {
        case idle
        case scanning
        case candidates
        case applying
        case result
    }

    @Published var phase: Phase = .idle
    @Published var progressScanned: UInt64 = 0
    @Published var progressCurrent: String = ""
    @Published var entries: [VolePlanEntry] = []
    @Published var selectedIDs: Set<String> = []
    @Published var report: VoleReport?
    @Published var errorMessage: String?
    @Published var showFDAAlert: Bool = false
    @Published var voleVersion: String = ""
    @Published var coverageNote: String?

    private var process = VoleProcess()
    private var fullPlanURL: URL?
    private var fullPlan: VolePlan?

    func refreshVersion() {
        Task {
            let proc = VoleProcess()
            var lines: [String] = []
            let exit = await proc.run(arguments: ["--version"]) { line in
                lines.append(line)
            }
            if case .success = exit {
                voleVersion = lines.last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            }
        }
    }

    func startScan() {
        errorMessage = nil
        report = nil
        entries = []
        selectedIDs = []
        progressScanned = 0
        progressCurrent = ""
        if FDAProbe.looksDenied() {
            showFDAAlert = true
        }
        phase = .scanning

        Task {
            do {
                let dir = try PlanIO.cachesDirectory()
                let planURL = dir.appendingPathComponent("clean-full-\(UUID().uuidString).json")
                fullPlanURL = planURL
                let exit = await process.run(arguments: [
                    "clean", "--plan", "--json-stream", "--plan-out", planURL.path,
                ]) { [weak self] line in
                    Task { @MainActor in
                        self?.handleStreamLine(line)
                    }
                }
                await handlePlanExit(exit, planURL: planURL)
            } catch {
                phase = .idle
                errorMessage = error.localizedDescription
            }
        }
    }

    func cancel() {
        Task { await process.cancel() }
    }

    func applySelected() {
        guard let fullPlan else {
            errorMessage = "缺少 plan，请重新扫描"
            return
        }
        if PlanIO.isExpired(fullPlan) {
            errorMessage = "计划已过期，请重新扫描"
            phase = .idle
            return
        }
        let filtered = PlanIO.filter(plan: fullPlan, selectedIDs: selectedIDs)
        guard !filtered.entries.isEmpty else {
            errorMessage = "请至少选择一项"
            return
        }
        phase = .applying
        errorMessage = nil

        Task {
            do {
                let dir = try PlanIO.cachesDirectory()
                let applyURL = dir.appendingPathComponent("clean-apply-\(UUID().uuidString).json")
                try PlanIO.write(filtered, to: applyURL)
                defer { try? FileManager.default.removeItem(at: applyURL) }

                var lastReport: VoleReport?
                let exit = await process.run(arguments: [
                    "clean", "--apply", applyURL.path, "--json-stream",
                ]) { [weak self] line in
                    Task { @MainActor in
                        if let event = try? VoleStreamEvent.decodeNDJSONLine(line) {
                            if case let .done(report) = event {
                                lastReport = report
                            }
                            if case let .progress(scanned, current) = event {
                                self?.progressScanned = scanned
                                self?.progressCurrent = current
                            }
                        }
                    }
                }
                cleanupFullPlan()
                switch exit {
                case .success:
                    report = lastReport
                    phase = .result
                case .cancelled:
                    errorMessage = "已取消（可能已部分清理）"
                    report = lastReport
                    phase = .result
                case .failed(let message):
                    errorMessage = message
                    phase = .candidates
                }
            } catch {
                errorMessage = error.localizedDescription
                phase = .candidates
            }
        }
    }

    func reset() {
        cleanupFullPlan()
        phase = .idle
        entries = []
        selectedIDs = []
        report = nil
        errorMessage = nil
        coverageNote = nil
    }

    private func handleStreamLine(_ line: String) {
        guard let event = try? VoleStreamEvent.decodeNDJSONLine(line) else { return }
        switch event {
        case let .progress(scanned, current):
            progressScanned = scanned
            progressCurrent = current
        case .candidate, .skipped, .done, .aborted:
            break
        }
    }

    private func handlePlanExit(_ exit: SidecarExit, planURL: URL) async {
        switch exit {
        case .success:
            do {
                let plan = try PlanIO.read(from: planURL)
                fullPlan = plan
                coverageNote = plan.coverageNote
                entries = plan.entries.filter { $0.skipReason == nil }
                selectedIDs = Set(entries.map(\.id))
                phase = .candidates
            } catch {
                errorMessage = "无法读取 plan: \(error.localizedDescription)"
                phase = .idle
            }
        case .cancelled:
            cleanupFullPlan()
            phase = .idle
        case .failed(let message):
            cleanupFullPlan()
            errorMessage = message
            if message.localizedCaseInsensitiveContains("permission")
                || message.localizedCaseInsensitiveContains("tcc")
                || message.contains("Operation not permitted") {
                showFDAAlert = true
            }
            phase = .idle
        }
    }

    private func cleanupFullPlan() {
        if let url = fullPlanURL {
            try? FileManager.default.removeItem(at: url)
        }
        fullPlanURL = nil
    }
}
```

- [ ] **Step 2: 编译确认**

```bash
xcodebuild -scheme vole-macos -configuration Debug -destination 'platform=macOS' build 2>&1 | tail -30
```

Expected: `BUILD SUCCEEDED`。若 actor/`@MainActor` 编译错误，按编译器提示微调（保持对外 API 不变）。

- [ ] **Step 3: Commit**

```bash
git add vole-macos/Clean/CleanSession.swift
git commit -m "$(cat <<'EOF'
feat: add CleanSession plan/apply state machine

Drive scan → select → apply using --plan-out as the authoritative plan and
mapping sidecar exit codes into UI phases.
EOF
)"
```

---

### Task 8: SwiftUI 五态界面

**Files:**
- Create: `vole-macos/Clean/CleanRootView.swift`
- Create: `vole-macos/Clean/CleanIdleView.swift`
- Create: `vole-macos/Clean/CleanScanningView.swift`
- Create: `vole-macos/Clean/CleanCandidatesView.swift`
- Create: `vole-macos/Clean/CleanApplyingView.swift`
- Create: `vole-macos/Clean/CleanResultView.swift`
- Modify: `vole-macos/ContentView.swift`
- Modify: `vole-macos/vole_macosApp.swift`

**Interfaces:**
- Consumes: `CleanSession`
- Produces: 可交互的五态 UI + FDA alert + 清理确认对话框

- [ ] **Step 1: 实现视图（最小可用，系统控件）**

`CleanRootView.swift`：

```swift
import SwiftUI

struct CleanRootView: View {
    @ObservedObject var session: CleanSession

    var body: some View {
        Group {
            switch session.phase {
            case .idle: CleanIdleView(session: session)
            case .scanning: CleanScanningView(session: session)
            case .candidates: CleanCandidatesView(session: session)
            case .applying: CleanApplyingView(session: session)
            case .result: CleanResultView(session: session)
            }
        }
        .frame(minWidth: 520, minHeight: 420)
        .padding()
        .alert("需要完全磁盘访问", isPresented: $session.showFDAAlert) {
            Button("打开系统设置") { FDAProbe.openSettings() }
            Button("稍后", role: .cancel) {}
        } message: {
            Text("未授权时扫描结果可能偏少。请在「隐私与安全性 → 完全磁盘访问」中勾选 vole-macos。")
        }
        .onAppear { session.refreshVersion() }
    }
}
```

`CleanIdleView.swift`：

```swift
import SwiftUI

struct CleanIdleView: View {
    @ObservedObject var session: CleanSession

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("清理").font(.largeTitle.bold())
            Text("扫描可清理的缓存与残留，确认后移到废纸篓。")
                .foregroundStyle(.secondary)
            if !session.voleVersion.isEmpty {
                Text("sidecar: \(session.voleVersion)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let error = session.errorMessage {
                Text(error).foregroundStyle(.red)
            }
            Button("扫描") { session.startScan() }
                .keyboardShortcut(.defaultAction)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
```

`CleanScanningView.swift`：

```swift
import SwiftUI

struct CleanScanningView: View {
    @ObservedObject var session: CleanSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("扫描中…").font(.title2.bold())
            ProgressView()
            Text("已扫描 \(session.progressScanned) 项")
            Text(session.progressCurrent).lineLimit(2).foregroundStyle(.secondary)
            Button("取消", role: .cancel) { session.cancel() }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
```

`CleanCandidatesView.swift`：

```swift
import SwiftUI

struct CleanCandidatesView: View {
    @ObservedObject var session: CleanSession
    @State private var confirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("候选").font(.title2.bold())
                Spacer()
                Button("全选") { session.selectedIDs = Set(session.entries.map(\.id)) }
                Button("全不选") { session.selectedIDs = [] }
            }
            if let note = session.coverageNote {
                Text(note).font(.caption).foregroundStyle(.secondary)
            }
            if let error = session.errorMessage {
                Text(error).foregroundStyle(.red)
            }
            List {
                ForEach(session.entries) { entry in
                    Toggle(isOn: Binding(
                        get: { session.selectedIDs.contains(entry.id) },
                        set: { on in
                            if on { session.selectedIDs.insert(entry.id) }
                            else { session.selectedIDs.remove(entry.id) }
                        }
                    )) {
                        VStack(alignment: .leading) {
                            Text(entry.label)
                            Text("\(ByteFormat.string(entry.size)) · \(entry.ruleID)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(entry.path)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            HStack {
                Text("已选 \(session.selectedIDs.count) · 共 \(session.entries.count)")
                Spacer()
                Button("重新扫描") { session.startScan() }
                Button("清理到废纸篓") { confirm = true }
                    .keyboardShortcut(.defaultAction)
                    .disabled(session.selectedIDs.isEmpty)
            }
        }
        .confirmationDialog("将把已选项目移到废纸篓", isPresented: $confirm, titleVisibility: .visible) {
            Button("确认清理", role: .destructive) { session.applySelected() }
            Button("取消", role: .cancel) {}
        }
    }
}
```

`CleanApplyingView.swift`：

```swift
import SwiftUI

struct CleanApplyingView: View {
    @ObservedObject var session: CleanSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("清理中…").font(.title2.bold())
            ProgressView()
            Text(session.progressCurrent).foregroundStyle(.secondary)
            Text("取消后可能已有部分项目进入废纸篓。").font(.caption).foregroundStyle(.secondary)
            Button("取消", role: .cancel) { session.cancel() }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
```

`CleanResultView.swift`：

```swift
import SwiftUI

struct CleanResultView: View {
    @ObservedObject var session: CleanSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("完成").font(.title2.bold())
            if let report = session.report {
                Text("成功 \(report.succeeded) · 跳过 \(report.skipped) · 失败 \(report.failed)")
                Text("移入废纸篓 \(ByteFormat.string(report.trashedBytes))")
            }
            if let error = session.errorMessage {
                Text(error).foregroundStyle(.orange)
            }
            Button("完成") { session.reset() }
                .keyboardShortcut(.defaultAction)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
```

`ContentView.swift`：

```swift
import SwiftUI

struct ContentView: View {
    @ObservedObject var session: CleanSession

    var body: some View {
        CleanRootView(session: session)
    }
}
```

`vole_macosApp.swift`：

```swift
import SwiftUI

@main
struct vole_macosApp: App {
    @StateObject private var session = CleanSession()

    var body: some Scene {
        WindowGroup {
            ContentView(session: session)
        }
    }
}
```

- [ ] **Step 2: 编译 + 单测全绿**

```bash
xcodebuild test -scheme vole-macos -destination 'platform=macOS' 2>&1 | tail -40
```

Expected: `TEST SUCCEEDED` / `BUILD SUCCEEDED`。

- [ ] **Step 3: Commit**

```bash
git add vole-macos/Clean vole-macos/ContentView.swift vole-macos/vole_macosApp.swift
git commit -m "$(cat <<'EOF'
feat: wire Clean SwiftUI flow for scan, select, and apply

Present the five-phase clean wizard with FDA alert and trash confirmation.
EOF
)"
```

---

### Task 9: 人工验收与收口文档

**Files:**
- Modify: `README.md`（补验收结果说明可选）
- Create: `docs/findings/2026-07-desktop-clean-mvp.md`（简短 findings）

**Interfaces:**
- Consumes: 已实现 App
- Produces: findings 勾选；确认设计验收清单

- [ ] **Step 1: 按设计 §8 手工跑通**

1. 两仓并列 → Xcode Run 成功，UI 显示 sidecar 版本  
2. 点「扫描」→ 候选列表出现 → 勾选子集 → 确认 → 废纸篓可见对应项  
3. 扫描中点「取消」→ 立刻回空闲  
4. 去掉 FDA 授权后启动扫描 → 出现提示并可打开设置  

记录任何偏差到 findings。

- [ ] **Step 2: 写 findings**

```markdown
# Desktop Clean MVP findings

**日期**：2026-07-30  
**状态**：完成 / 部分（按实测勾）  
**设计**：`docs/wukong-code/specs/2026-07-30-2328-desktop-clean-mvp-design.md`

## 验收

| 项 | 状态 |
|---|---|
| Bundle 含 vole + rules | |
| plan → 勾选 → 废纸篓 | |
| 取消扫描 | |
| FDA 提示 | |

## 备注

（实测问题、沙盒/签名观察、后续里程碑）
```

- [ ] **Step 3: Commit**

```bash
git add docs/findings/2026-07-desktop-clean-mvp.md README.md
git commit -m "$(cat <<'EOF'
docs: record desktop clean MVP acceptance findings

Capture manual verification results for the local SwiftUI clean prototype.
EOF
)"
```

---

## Spec Coverage (self-review)

| Spec 要求 | Task |
|---|---|
| 关 App Sandbox / Hardened Runtime / Script Sandboxing | Task 1 |
| embed `vole` + rules 布局 | Task 2 |
| NDJSON / Plan Codable | Task 3 |
| `--plan-out` 权威 + 过滤 entries | Task 4, 7 |
| 退出码 0/130/1 | Task 5, 7 |
| FDA 主动探测 | Task 6, 7, 8 |
| 五态 UI + 确认对话框 | Task 8 |
| TTL UI 预检 + CLI 为安全边界 | Task 4, 7 |
| plan 用后即删 | Task 7 |
| 互斥锁错误展示 | Task 5 映射 + Task 7 `errorMessage` |
| 人工验收 | Task 9 |
| GPL LICENSE | Task 1 |
| 零改 vole 仓 | Global Constraints |

无 TBD / 无「similar to Task N」占位。
