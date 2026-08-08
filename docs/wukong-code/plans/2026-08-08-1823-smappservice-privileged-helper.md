# SMAppService Privileged Helper Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use wukong-code:executing-plans（本仓默认 inline）或 wukong-code:subagent-driven-development。Steps 用 checkbox（`- [x]`）跟踪。

**Goal:** 按 [`../specs/2026-08-08-1822-smappservice-privileged-helper-design.md`](../specs/2026-08-08-1822-smappservice-privileged-helper-design.md) 交付可编译的特权助手**骨架**：Helper target、LaunchDaemon plist、App 注册点与 XPC ping、测试与文档；不接线真实删除。

**Architecture:** SMAppService.daemon 注册包内 LaunchDaemon；App 经特权 NSXPC 调用窄协议；sidecar `vole` 仍负责 Clean MVP。本 PR 止于骨架；可用通道另 PR。

**Tech Stack:** Swift / SwiftUI、ServiceManagement (`SMAppService`)、Foundation XPC、Xcode 26、macOS 26.5 deployment。

## Global Constraints

- 规格权威：`docs/wukong-code/specs/2026-08-08-1822-smappservice-privileged-helper-design.md`
- **禁止**改兄弟仓 `vole` 的 `sudo -v` / `PrivilegeBackend` 冒充完成
- Helper **无**通用 shell；骨架仅 `ping`
- 不改 Clean MVP 主路径行为
- 合入 PR 用 **merge commit**（非 squash）
- 标识：Mach `cn.waytoai.vole-macos.helper`；plist `cn.waytoai.vole-macos.helper.plist`；二进制 `VolePrivilegedHelper`

## File map

| 文件 | 职责 |
|---|---|
| `PrivilegedHelper/main.swift` | Helper 入口：XPC listener |
| `PrivilegedHelper/HelperXPCService.swift` | `VoleHelperProtocol` 实现 + 客户端校验 |
| `PrivilegedHelper/VoleHelperProtocol.swift` | XPC 协议（与 App 侧保持同步） |
| `LaunchDaemons/cn.waytoai.vole-macos.helper.plist` | BundleProgram + MachServices |
| `vole-macos/Privilege/VoleHelperProtocol.swift` | App 侧协议副本 |
| `vole-macos/Privilege/HelperServiceIDs.swift` | 常量 |
| `vole-macos/Privilege/HelperRegistration.swift` | SMAppService register/status/openSettings |
| `vole-macos/Privilege/HelperXPCClient.swift` | 特权 XPC client + ping |
| `vole-macos.xcodeproj/project.pbxproj` | Helper target、依赖、Embed |
| `vole-macosTests/PrivilegeHelperTests.swift` | 常量与状态映射测试 |
| `README.md` | 骨架状态与剩余步骤 |

---

### Task 1: Helper 可执行文件与 plist

**Files:**
- Create: `PrivilegedHelper/main.swift`
- Create: `PrivilegedHelper/HelperXPCService.swift`
- Create: `PrivilegedHelper/VoleHelperProtocol.swift`
- Create: `LaunchDaemons/cn.waytoai.vole-macos.helper.plist`

**Interfaces:**
- Produces: `VolePrivilegedHelper` tool；Mach 服务名见 Global Constraints

- [x] **Step 1: 写协议 + Helper 服务 + main**
- [x] **Step 2: 写 LaunchDaemon plist（`BundleProgram` = `Contents/MacOS/VolePrivilegedHelper`）**
- [x] **Step 3: 在 pbxproj 增加 `VolePrivilegedHelper` target（product-type tool）**
- [x] **Step 4: `xcodebuild -scheme VolePrivilegedHelper -configuration Debug build` 通过**

```bash
cd /Users/wukong/Documents/vole-macos
xcodebuild -scheme VolePrivilegedHelper -configuration Debug build
```

- [x] **Step 5: Commit**

```bash
git commit -m "$(cat <<'EOF'
feat: add VolePrivilegedHelper XPC daemon skeleton

EOF
)"
```

---

### Task 2: App 注册点与 Embed

**Files:**
- Create: `vole-macos/Privilege/*.swift`
- Modify: `project.pbxproj`（依赖 Helper、Copy Files → LaunchDaemons + MacOS）
- Modify: `README.md`

**Interfaces:**
- `HelperRegistration.status` / `register()` / `unregister()` / `openSystemSettings()`
- `HelperXPCClient.ping()` — 仅当 `.enabled`

- [x] **Step 1: App 侧 Privilege 源码**
- [x] **Step 2: Embed：Copy Helper → `Contents/MacOS/`；Copy plist → `Contents/Library/LaunchDaemons/`**
- [x] **Step 3: `xcodebuild -scheme vole-macos -configuration Debug build` 通过**（sidecar 脚本若缺 `../vole` 可 `VOLE_SRC` 或允许失败时至少编过 Helper+App 源码；优先完整 build）
- [x] **Step 4: Commit**

```bash
git commit -m "$(cat <<'EOF'
feat: register SMAppService daemon and embed helper

EOF
)"
```

---

### Task 3: 测试与文档收尾

**Files:**
- Create: `vole-macosTests/PrivilegeHelperTests.swift`
- Modify: README；本 plan 勾选

- [x] **Step 1: 单测常量与 `HelperRegistrationStatus` 映射**
- [x] **Step 2: `xcodebuild test -scheme vole-macos -only-testing:vole-macosTests/PrivilegeHelperTests`（或全量 unit）**
- [x] **Step 3: README 标明骨架 / 剩余步骤**
- [x] **Step 4: Commit + PR（merge commit）**

```bash
git commit -m "$(cat <<'EOF'
test: cover privileged helper identifiers and status mapping

EOF
)"
```

---

## 可用通道增量（已合入 [#3](https://github.com/wukongnotnull/vole-macos/pull/3) · 真机已验收）

1. [x] XPC `removeAuthorizedPaths` / `bootoutLaunchdLabel` + `PathAuthorization` 白名单（fail-closed）
2. [x] Clean UI 接线与无 Helper 降级；Uninstall 扩展点 `PrivilegedApply`
3. [x] Hardened Runtime 启用；公证凭据缺失已文档化（不伪造）
4. [x] 真机批准流：BTM/daemon `enabled` + XPC ping `uid==0`（2026-08-09；证据见 README）
5. [x] vole coverage「仍未移植」删除（配对 PR）+ 可选 PrivilegeBackend design（仍未做）

## Spec coverage

| 设计章节 | 计划落点 |
|---|---|
| §2 SMAppService.daemon | Task 1–2 |
| §3.2 骨架成功标准 | Task 1–3 |
| §4 XPC ping / 校验 | Task 1–2 |
| §5 批准流程 API | Task 2 |
| §8 不改 CLI sudo | 全局约束 |
| §9.1 验收 | Task 3 |

Plan complete. 默认 **Inline** 执行 Task 1→3。
