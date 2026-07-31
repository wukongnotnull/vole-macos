# vole-macos

Vole 的 macOS SwiftUI 桌面端（GPL-3.0）。本里程碑：内嵌 `vole` sidecar，提供 `clean` 的 plan → 勾选 → apply（默认废纸篓）。

## 前置

- macOS + Xcode（工程模板部署目标以 `.xcodeproj` 为准）
- Rust toolchain（与兄弟仓 `vole` 的 `rust-toolchain.toml` 一致；默认 `~/.cargo/bin/cargo`）
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
4. 若报 `cargo not found`：确认已装 rustup，且 `~/.cargo/bin/cargo` 存在；或在 Build Phase「Embed vole sidecar」里设环境变量 `CARGO=/绝对路径/cargo`
5. 若清理扫描结果异常少：系统设置 → 隐私与安全性 → 完全磁盘访问，勾选 **vole-macos**

## 设计

见 [`docs/wukong-code/specs/2026-07-30-2328-desktop-clean-mvp-design.md`](docs/wukong-code/specs/2026-07-30-2328-desktop-clean-mvp-design.md)。

## 验收

MVP 自动化与人工清单见 [`docs/findings/2026-07-desktop-clean-mvp.md`](docs/findings/2026-07-desktop-clean-mvp.md)。
