# vole-macos

Vole 的 macOS SwiftUI 桌面端（GPL-3.0）。本里程碑：内嵌 `vole` sidecar，提供 `clean` 的 plan → 勾选 → apply（默认废纸篓）；系统路径经 SMAppService 特权助手永久删除。

## 前置

- macOS + Xcode（工程模板部署目标以 `.xcodeproj` 为准）
- Rust toolchain（与兄弟仓 `vole` 的 `rust-toolchain.toml` 一致；默认 `~/.cargo/bin/cargo`）
- 兄弟仓：本仓与 `vole` 并列，例如：

```text
Documents/vole
Documents/vole-macos
```

可用环境变量 `VOLE_SRC` 覆盖默认路径 `$(SRCROOT)/../vole`。在 git worktree 下构建时务必设置 `VOLE_SRC`。

## 运行

1. 用 Xcode 打开 `vole-macos.xcodeproj`
2. 确认 Build Settings：`ENABLE_APP_SANDBOX=NO`、`ENABLE_USER_SCRIPT_SANDBOXING=NO`；App 与 Helper 已启用 **Hardened Runtime**
3. Product → Run（首次会 `cargo build -p vole-cli --release`，较慢）
4. 若报 `cargo not found`：确认已装 rustup，且 `~/.cargo/bin/cargo` 存在；或在 Build Phase「Embed vole sidecar」里设环境变量 `CARGO=/绝对路径/cargo`
5. 若清理扫描结果异常少：系统设置 → 隐私与安全性 → 完全磁盘访问，勾选 **vole-macos**
6. 系统路径清理：首页「启用特权助手」→ 系统设置批准后台项 → 状态「已启用」且 ping `uid=0`

## 设计

- Clean MVP：[`docs/wukong-code/specs/2026-07-30-2328-desktop-clean-mvp-design.md`](docs/wukong-code/specs/2026-07-30-2328-desktop-clean-mvp-design.md)
- 特权助手（SMAppService）：[`docs/wukong-code/specs/2026-08-08-1822-smappservice-privileged-helper-design.md`](docs/wukong-code/specs/2026-08-08-1822-smappservice-privileged-helper-design.md)

## 特权助手（可用通道）

当前目标档位：**可用通道**（相对骨架的增量）：

- Target：`VolePrivilegedHelper`（特权 XPC：`ping` / `removeAuthorizedPaths` / `bootoutLaunchdLabel`）
- 注册：`HelperRegistration` → `SMAppService.daemon`
- Bundle：`Contents/MacOS/VolePrivilegedHelper` + `Contents/Library/LaunchDaemons/cn.waytoai.volemacos.helper.plist`
- 白名单 fail-closed：见 `PathAuthorization`（永不含 `/Library/Updates`、`/macOS Install Data`）
- Clean UI：首页启用/状态卡；候选页提示；apply 时用户域走 sidecar，系统路径走 Helper；无 Helper 时**跳过**系统路径并明示，不假装成功
- Uninstall UI：尚未落地；`PrivilegedApply` 为共享扩展点

### Hardened Runtime / 公证

| 项 | 状态 |
|---|---|
| Hardened Runtime（App + Helper） | 已启用（`ENABLE_HARDENED_RUNTIME=YES`） |
| Developer ID Application 签名 | 本机存在 `Developer ID Application: Kong Wu (WCYC8XY4V2)` |
| 公证（notarytool） | **阻塞**：Keychain 中无 `notarytool` 凭据（无 `AC_PASSWORD` / keychain-profile）。需人工执行一次 `xcrun notarytool store-credentials` 后才能自动化提交 |

### 真机批准流验收（人工）

1. `VOLE_SRC=…/vole xcodebuild -scheme vole-macos -configuration Debug build`
2. 运行 App →「启用特权助手」→ 在系统设置批准
3. 状态变为「已启用」，点击「重新检查」应显示 `uid=0`
4. 勾选白名单内系统路径清理，确认永久删除；关闭后台项后系统路径应被跳过

## 验收

MVP 自动化与人工清单见 [`docs/findings/2026-07-desktop-clean-mvp.md`](docs/findings/2026-07-desktop-clean-mvp.md)。
特权助手见 design §9.2。
