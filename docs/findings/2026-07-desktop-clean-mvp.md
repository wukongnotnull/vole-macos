# Desktop Clean MVP findings

**日期**：2026-07-30  
**状态**：自动化门禁通过；三项 UI 人工验收列为合并后跟进（不阻塞 PR #1）  
**设计**：[`docs/wukong-code/specs/2026-07-30-2328-desktop-clean-mvp-design.md`](../wukong-code/specs/2026-07-30-2328-desktop-clean-mvp-design.md)

## 验收

| 项 | 状态 |
|---|---|
| Bundle 含 vole + rules | ✅ 自动化已验证 |
| 两仓并列 → Xcode Run / 启动 | ✅ 自动化已验证 |
| plan → 勾选 → 废纸篓 | ⏳ 合并后人工跟进 |
| 取消扫描 | ⏳ 合并后人工跟进（单测已覆盖 exit 映射） |
| FDA 提示 | ⏳ 合并后人工跟进 |

## 自动化验证（2026-07-31）

| 检查 | 结果 |
|---|---|
| `xcodebuild -scheme vole-macos -configuration Debug build` | **BUILD SUCCEEDED** |
| `Contents/MacOS/vole` 存在且可执行 | ✅（≈5.6 MB） |
| `Contents/share/vole/rules/*.toml` | ✅（6 条规则） |
| `vole --version` | `vole 1.2.0` |
| 嵌入 sidecar `clean --plan-out` | exit 0，990 entries，ttl 900s |
| `open` 启动 App | 进程 `vole-macos` 正常拉起 |
| 单元测试 `vole-macosTests` | ✅（含 cancel/success 优先级、schema_version 校验） |

## Code review 修复（合入前）

| 项 | 处理 |
|---|---|
| `cancelRequested` 掩盖 exit 0 | `mapExitCode`：`code == 0` 优先于 cancel |
| TTL 过期未清状态 | `applySelected` 过期时清 plan/entries/selected/缓存文件 |
| 未校验 `schema_version` | `PlanIO.read` 要求 `== 1`，否则 `PlanIOError.unsupportedSchema` |

DerivedData 产物路径（本机）：

```text
~/Library/Developer/Xcode/DerivedData/vole-macos-hlamkhulrvdcsefqlvynjiehfykw/Build/Products/Debug/vole-macos.app
```

## 待人工步骤

1. **plan → 勾选 → 废纸篓**  
   Xcode Run → 点「扫描」→ 候选列表出现 → 勾选少量低风险项 → 确认 → 打开废纸篓核对对应文件。

2. **取消扫描**  
   扫描进行中点「取消」→ UI 应立刻回到空闲（`SidecarRunner` 映射 exit 130 → `.cancelled`，单测已覆盖）。

3. **FDA 提示**  
   系统设置 → 隐私与安全性 → 完全磁盘访问 → 取消勾选 **vole-macos** → 重启 App 点「扫描」→ 应弹出「需要完全磁盘访问」并可「打开系统设置」（`FDAProbe.looksDenied()` 探测 `~/Library/Mail` 列表权限）。

## 备注

- **沙盒 / 签名**：Debug 构建 `ENABLE_APP_SANDBOX=NO`、`ENABLE_HARDENED_RUNTIME=NO`；entitlements 仅 `get-task-allow` + `user-selected.read-only`（开发态）。
- **零改 vole 仓**：sidecar 由 Build Phase `Embed vole sidecar` 从并列 `../vole` 编译嵌入；`VOLE_SRC` 可覆盖路径。
- **后续里程碑**：Developer ID 签名与公证、Release 硬化、按 rule 分组 UI、installer / 自动更新等非本 MVP 范围。
