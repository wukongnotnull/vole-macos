# Vole macOS：SMAppService / PrivilegedHelper 设计

- 日期：2026-08-08 18:22
- 状态：已批准（闸控轨 D1：用户明确「批准执行轨 D1」；本文件为桌面仓专用 design）
- 仓库：`vole-macos`（主战场）；`vole` CLI 仅在 Helper **可用通道落地后** 才改 coverage「仍未移植」句 / 可选 `PrivilegeBackend` 适配
- 依据：
  - `vole` [`2026-08-08-1727-mole-parity-roadmap-design.md`](https://github.com/wukongnotnull/vole/blob/main/docs/wukong-code/specs/2026-08-08-1727-mole-parity-roadmap-design.md) §1.2 C / §3.6 / §4.2
  - `vole` 计划 [`2026-08-08-1739-mole-parity-closeout-gated-rails.md`](https://github.com/wukongnotnull/vole/blob/main/docs/wukong-code/plans/2026-08-08-1739-mole-parity-closeout-gated-rails.md) Task D1
  - 本仓既有 [`2026-07-30-2328-desktop-clean-mvp-design.md`](2026-07-30-2328-desktop-clean-mvp-design.md)（Clean MVP：sidecar；明确不做 SMAppService）

## 1. 结论

在桌面仓引入 **SMAppService 注册的 root LaunchDaemon（特权助手）**，经 **特权 XPC** 向 App 提供窄接口；**不**用 CLI `sudo -v` 冒充 Helper，**不**把清理编排搬进 Helper。

本里程碑可交付两档（按实现进度诚实标注）：

| 档位 | 含义 | coverage「仍未移植」 |
|---|---|---|
| **骨架** | design + 可编译 Helper target + App 注册点 + XPC ping；未完成真实删除/unload | **保留** |
| **可用通道** | 用户批准后 `status == .enabled`，XPC 可对白名单路径做永久删除或 `launchctl bootout` | **删除或改写** |

首版实现目标默认落在 **骨架**；可用通道为后续同轨增量。

## 2. 已锁定决策

| 项 | 结论 |
|---|---|
| API 代际 | **SMAppService.daemon**（macOS 13+）；**不用** legacy `SMJobBless` / `/Library/PrivilegedHelperTools` 安装路径 |
| 「PrivilegedHelper」含义 | 产品语义上的特权助手 = SMAppService 管理的 **LaunchDaemon + 特权 XPC**；文档可继续写 PrivilegedHelper，实现不走 Bless |
| 部署下限 | 与现工程一致：`MACOSX_DEPLOYMENT_TARGET = 26.5`（远高于 SMAppService 门槛） |
| Bundle 布局 | Daemon plist：`Contents/Library/LaunchDaemons/<label>.plist`；可执行文件：`BundleProgram` 相对包路径（如 `Contents/MacOS/VolePrivilegedHelper`） |
| 进程角色 | App（UI）↔ Helper（root，窄 XPC）；sidecar `vole` 仍负责 Clean MVP 的 plan/apply |
| 提权分工 | 见 §4 |
| CLI | 本里程碑 **零改** `vole` 的 `sudo -v` / `PrivilegeBackend`；禁止用交互 sudo 冒充桌面 Helper |
| 签名 | 开发阶段可 ad-hoc / 团队签名；分发前须同一 Team ID 签 App+Helper；Hardened Runtime / 公证为本轨后续，不阻塞骨架 |
| 许可证 | GPL-3.0-only（与仓一致） |

## 3. 目标与成功标准

### 3.1 目标

用户在系统设置中**批准一次**后台项后，桌面 App 获得持久、可探测的 root 通道，用于系统路径删除 / LaunchDaemon unload 等特权操作；Clean 用户域路径继续走 sidecar。

### 3.2 成功标准（骨架）

1. Xcode 工程含独立 target `VolePrivilegedHelper`，可编译
2. App Bundle 构建产物含 LaunchDaemon plist + Helper 可执行文件（Copy / Embed）
3. App 侧存在 `SMAppService.daemon(plistName:)` 注册 / 查状态 / 打开系统设置的注册点 API
4. XPC 协议至少含 `ping`（返回 pid/uid）；Helper 在 `shouldAcceptNewConnection` 校验调用方 Team ID
5. 单元测试覆盖：服务标识常量、状态枚举映射、未批准时 client 不静默假装已就绪
6. 文档写明剩余步骤（真实 privileged apply、UI 入口、CLI 适配）

### 3.3 成功标准（可用通道 · 后续）

1. 用户批准后 `SMAppService.status == .enabled`
2. XPC `removePaths` / `bootoutLaunchdLabel`（名称以实施为准）仅接受**显式白名单**路径/标签
3. App 在系统路径 clean/uninstall 场景可经 Helper 完成，而非要求终端 `sudo`
4. 此后才允许改 `vole` coverage「仍未移植」句

### 3.4 明确不做（本轨 / 本代际）

- 改 CLI `sudo -v` 语义冒充 Helper
- 把 `vole clean` 编排逻辑迁入 Helper / 复刻规则引擎
- Helper 执行任意 shell / 任意路径删除（禁止「远程 root shell」）
- FDA 替代方案（FDA 仍是用户域；Helper 解决的是 **Unix root**，不是 TCC）
- MAS 分发、Sparkle、完整 onboarding 文案精修
- optimize 闸控轨 G2–G5
- uninstall 与 Helper 的「深度边角」全量（路线图 §1.2 C 第二项；本轨只留扩展点）

## 4. 架构与提权分工

```
┌──────────────────────────────────────────┐
│  Vole.app (SwiftUI)                      │
│  CleanSession / future Uninstall UI      │
│         │                    │           │
│         ▼                    ▼           │
│  SidecarRunner          HelperClient     │
│  (Process -> vole)      (SMAppService +  │
│                         NSXPC privileged) │
└─────────┬────────────────────┬───────────┘
          │                    │
          ▼                    ▼
┌──────────────────┐  ┌────────────────────┐
│ Contents/MacOS/  │  │ LaunchDaemon       │
│ vole + rules     │  │ VolePrivilegedHelper│
│ user-domain ops  │  │ root · narrow XPC  │
└──────────────────┘  └────────────────────┘
```
### 4.1 谁做什么

| 能力 | 负责方 | 说明 |
|---|---|---|
| Clean plan / 勾选 / 用户域 apply（废纸篓） | sidecar `vole` | 保持 MVP；不经 Helper |
| 系统路径 plan 枚举（可读子集） | sidecar `vole`（无 root） | 与 CLI 一致；不可读则 skip |
| 系统路径 **永久删除** / `launchctl bootout` | **Helper（未来可用通道）** | App 经 XPC 下发已校验请求 |
| CLI 终端提权 | 既有 `PrivilegeBackend` + `sudo -n` | 桌面轨不替换 CLI；双轨并存 |
| 注册 / 批准引导 | App `HelperRegistration` | `register` → `.requiresApproval` → 打开系统设置 |

### 4.2 标识（锁定）

| 项 | 值 |
|---|---|
| App bundle id | `cn.waytoai.vole-macos` |
| Helper Mach 服务 | `cn.waytoai.vole-macos.helper` |
| LaunchDaemon plist 文件名 | `cn.waytoai.vole-macos.helper.plist` |
| Helper 可执行文件名 | `VolePrivilegedHelper` |
| Team | `WCYC8XY4V2`（与现工程一致） |

### 4.3 XPC 边界（骨架 → 可用）

**骨架协议（必做）：**

```swift
@objc protocol VoleHelperProtocol {
    func ping(reply: @escaping (_ pid: Int32, _ uid: Int32) -> Void)
}
```

**可用通道扩展（后续，本 design 预留，非骨架必做）：**

```swift
@objc protocol VoleHelperProtocol {
    func ping(reply: @escaping (_ pid: Int32, _ uid: Int32) -> Void)
    /// 仅永久删除；路径必须通过 Helper 内白名单与规范化校验
    func removeAuthorizedPaths(_ paths: [String],
                               reply: @escaping (_ ok: Bool, _ error: String?) -> Void)
    func bootoutLaunchdLabel(_ label: String,
                             reply: @escaping (_ ok: Bool, _ error: String?) -> Void)
}
```

规则：

1. Helper **只**暴露显式方法；无「跑命令」通用入口
2. 连接选项：App → Helper 使用 `NSXPCConnection(machServiceName:options: .privileged)`
3. `listener(_:shouldAcceptNewConnection:)`：**拒绝**非本 Team ID / 非期望 bundle id 的客户端
4. 路径：realpath 规范化；拒绝 `..`、符号链接逃逸、白名单外前缀
5. 白名单初版（可用通道时写入代码常量，可随 CLI 系统规则对齐）：  
   `/Library/Caches`、`/Library/LaunchDaemons`、`/Library/LaunchAgents`、`/private/tmp`、`/private/var/tmp`、`/private/var/log`、`/private/var/db/diagnostics` 及既有 CLI 已支持的系统清理前缀；**永不**包含 `/Library/Updates`、`/macOS Install Data`、本地快照 API
6. 失败 fail-closed；错误字符串可给 UI，不抛未捕获异常跨进程

## 5. 安装与用户批准流程

```text
App 启动或用户点击「启用特权助手」
  → SMAppService.daemon(plistName: "cn.waytoai.vole-macos.helper.plist")
  → register()
  → status:
       .notRegistered → 提示注册失败 / 签名问题
       .requiresApproval → 打开系统设置（Login Items / Background）并说明需管理员批准
       .enabled → 允许创建 XPC 并 ping
       .notFound → Bundle 缺 plist/二进制（构建回归）
```

要点：

- 与 legacy Bless 不同：**不能**指望一次密码框完成安装；必须引导系统设置
- 用户关闭后台项后：status 变为不可用；App 须降级（系统路径跳过 / 提示），不得假装成功
- 卸载 App：应 `unregister()`（后续 UI）；骨架至少暴露 API

## 6. 威胁模型

| 威胁 | 缓解 |
|---|---|
| 任意进程连接 Helper 获 root | Team ID + bundle 校验；Mach 服务名固定；无通用 shell |
| 恶意/被篡改 App 发删除请求 | 同 Team 签名；分发阶段 Hardened Runtime + 公证；路径白名单 |
| 路径逃逸（symlink / `..`） | realpath + 前缀白名单；拒绝非常规路径 |
| Helper 扩大攻击面（常驻 root） | KeepAlive 可开，但接口极窄；无脚本引擎；日志用 `os_log` |
| 与 sidecar 双删竞态 | 系统路径特权操作**只**走 Helper 或只走 CLI，App 编排层选一；骨架阶段 App 仍不调系统删 |
| 用户误批后台项 | UI 文案说明用途；可随时在系统设置关闭 |
| 供应链：未签名 Helper | 构建失败可见；CI/本地 `codesign -dv` 自检（后续） |

**信任边界：** Helper 信任「同 Team 签名的 App」发出的已结构化请求，**不**信任路径字符串的业务语义（业务层仍应只发送 plan 已选路径）。

## 7. 与 Clean MVP / CLI 的关系

- Clean MVP **继续**短生命周期 sidecar；本轨不修改 plan/apply UI 主路径
- CLI 在终端场景继续 `sudo -n`；桌面 Helper **并行**存在，不是 CLI 后端替换
- 仅当可用通道验收后：`vole` coverage 去掉「仍未移植：桌面 SMAppService / 特权助手」；可选另开 design 做 `PrivilegeBackend` 桌面适配（**非**本骨架范围）

## 8. 非目标与禁区（重申）

- 禁止：未设计清晰时改 CLI `sudo -v`「假装」Helper 已完成
- 禁止：Helper 删除 `/Library/Updates`、`/macOS Install Data`、本地快照
- 禁止：本轨实现 G2–G5 optimize 长尾
- 禁止：交付时谎称「可用」——骨架必须在 README/计划中标明剩余步骤

## 9. 验收清单

### 9.1 骨架（本 PR 期望）

- [x] 本 design 入库
- [x] 实施 plan 入库
- [x] `VolePrivilegedHelper` target 可 `xcodebuild` 编译
- [x] App 含注册点与 XPC client 骨架
- [x] Bundle 内嵌 LaunchDaemon plist + Helper
- [x] 测试：标识与状态映射
- [x] vole 计划 Task D1 标注部分完成 + 阻塞项（Helper 未到「可用」则不改 coverage）

### 9.2 可用通道（后续 PR）

- [ ] 真机批准流 + ping uid==0
- [ ] 白名单删除 / bootout
- [ ] UI 入口与失败降级
- [ ] 改 vole coverage；必要时 PrivilegeBackend design

## 10. 开放问题（已拍板）

| 问题 | 决定 |
|---|---|
| SMAppService vs Bless | SMAppService.daemon |
| Helper 是否嵌入 app bundle | 是（Apple 现行模型） |
| 骨架是否改 vole coverage | **否** |
| 骨架是否接线 Clean apply | **否**（避免半成品提权路径） |
