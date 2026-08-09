# Vole macOS · UI 设计：侧栏 CLI 能力面扩容

- 日期：2026-08-09 14:54
- 状态：已批准（本会话 brainstorming：导航范围 B、交互深度 3、设置一并 B；方案 A）
- 仓库：`vole-macos`
- 上游依赖：[`2026-08-08-2245-vole-ui-shell-clean-design.md`](2026-08-08-2245-vole-ui-shell-clean-design.md)（壳与侧栏基线）；[`2026-08-09-1321-sidebar-modules-mvp.md`](../plans/2026-08-09-1321-sidebar-modules-mvp.md)（卸载 / 优化 / 状态已落地模式）；兄弟仓 `vole` CLI 全家桶（`2.5.0`：`analyze` / `history` / `purge` / `installer` / `touchid` / `update` / `remove`）
- 范围：**App 导航与设置入口扩到 CLI 能力面**；不改兄弟仓协议 / schema；不引入 Sparkle 旁路

## 1. 结论

主侧栏由四项扩为八项：**清理 · 卸载 · 优化 · 净化 · 安装包 · 分析 · 历史 · 状态**。  
净化 / 安装包复用 Plan 五态；分析对齐 CLI TUI 的目录钻取；历史为只读审计列表。  
设置面板本批增加 **Touch ID · 更新 · 自卸载**（不进主侧栏）。

本文件**覆盖** [`2245`](2026-08-08-2245-vole-ui-shell-clean-design.md) §2「分析/历史进更多或设置」：二者改入主侧栏。

## 2. 已锁定决策

| 项 | 结论 |
|---|---|
| 导航范围 | 主栏加 **分析 · 历史 · 净化 · 安装包** |
| 交互深度 | **全量对齐 CLI 主路径**（分析钻取；净化/安装包 plan→apply；历史 JSON 列表） |
| 设置 | 本批一并：**Touch ID / 更新 / 自卸载** |
| 架构 | **扩展现有模式**（`PlanModuleKind` + 专用 Session）；不抽象通用框架；不嵌终端 TUI |
| 侧栏顺序 | 清理 → 卸载 → 优化 → 净化 → 安装包 → 分析 → 历史 → 状态 |
| 协议 | 只消费现有 sidecar JSON / NDJSON；`schema_version` 不变；CLI 仓零改（除非实现中发现阻塞性缺口，另开 design） |

## 3. 侧栏与路由

### 3.1 `ShellModule`

新增 cases：`purge`、`installer`、`analyze`、`history`（保留 `clean` / `uninstall` / `optimize` / `status`）。  
`CaseIterable` 顺序与 §2 侧栏顺序一致。全部 `isAvailable == true`。  
标题：净化 / 安装包 / 分析 / 历史。图标选用 SF Symbols，风格贴近现有（如 `flame` / `shippingbox` / `chart.pie` / `clock`——实现时定稿，须可读且不与状态 `chart.bar` 混淆）。

### 3.2 `ShellView` 路由

| 模块 | 宿主 |
|---|---|
| purge / installer | `PlanModuleRootView` + `PlanModuleSession`（扩展 `PlanModuleKind`） |
| analyze | 新 `AnalyzeRootView` + `AnalyzeSession` |
| history | 新 `HistoryRootView` + `HistorySession` |
| 既有四项 | 不变 |

侧栏宽度可按需要小幅上调（当前约 132pt），保证八项中文标题不严重截断；最小窗口不低于现有量级。

## 4. 净化 / 安装包（Plan 五态）

扩展 `PlanModuleKind`：`purge`、`installer`。

- CLI：`purge|installer --plan --json-stream --plan-out` → 勾选 → `--apply <plan> --json-stream`
- 特权助手分区与 Clean / 卸载 / 优化相同（用户域废纸篓；系统路径经 Helper，未就绪则跳过）
- **永久删除**：UI 提供与 CLI `--permanent` 对齐的开关；**默认关闭**（废纸篓）。开启时确认文案必须明示永久删除
- 文案（标题 / 空闲 / 候选 / 确认 / 结果）中文先行，语气延续「田鼠工坊」
- 互斥锁：sidecar 已有 per-command mutex；UI 展示真实错误，不假成功

## 5. 分析（对齐 CLI TUI）

对齐 `vole analyze` 交互主路径（见 CLI `cmd_analyze_tui`）：

| 行为 | 规格 |
|---|---|
| 数据 | `analyze --json [PATH]`；解码 `AnalyzeOutput`（`entries` / `large_files` / `total_size` / `total_files`） |
| 默认根 | `$HOME`；提供「选择文件夹」改根并重新扫描 |
| 列表 | 名称 + 体积（tabular）+ 目录标识；按 sidecar 返回顺序展示 |
| 大文件区 | 展示 `large_files` 子集（与 CLI 同区角色） |
| 钻取 | 点目录 → 将该 path 压栈并重新 `analyze --json`；返回弹出栈 |
| 扫描中 | 展示路径与取消；取消映射 sidecar 中断语义 |
| 快照 tip | 若 CLI/协议侧有本地快照提示可消费则展示；本批**不**为 tip 单独扩协议——无字段则省略 |
| 非目标 | 不嵌入 ratatui；不在分析模块内删除文件 |

## 6. 历史

| 行为 | 规格 |
|---|---|
| 数据 | `history --json --limit <N>`；默认 limit=20，UI 可调（夹在 CLI 允许的 1…200） |
| 分区 | **操作会话**（command / 起止时间 / items / size / actions）与 **删除审计**（timestamp / mode / status / size / path） |
| 交互 | 只读列表；空态诚实；刷新按钮 |
| 非目标 | 无撤销 / 无从历史一键再执行 |

## 7. 设置：Touch ID · 更新 · 自卸载

在既有 `SettingsSheet`（Helper / FDA / 关于）下追加三组；视觉延续 SoilPanel / 现有分组风格。

### 7.1 Touch ID

- 进入设置或点刷新时跑 `touchid status`（优先 `--json` 若 CLI 支持；否则解析可读 stdout）
- 操作：启用 / 禁用，对齐 `touchid enable|disable`
- 失败展示真实错误；不假装已切换
- 测试：能 mock / 注入环境时避免真 PAM 挂起（对齐 CLI `VOLE_TEST_NO_AUTH` 精神）

### 7.2 更新

- `update --check`（`--json` 优先）展示是否有更新 / 当前通道说明
- 用户确认后执行完整更新（带非交互确认 flag，如 `--yes`）；Homebrew 管理安装时遵循 CLI 拦截/提示文案，不绕过
- 成功以安装后版本可读为准（刷新「关于」中的 sidecar 版本）

### 7.3 自卸载

- 先 `remove --dry-run`（`--json` 优先）列出待删项
- 确认后 `remove --yes`；**默认不**传 `--purge-oplog`（可选高级勾选，默认关）
- 文案强调：只删本工具安装产物与自身配置；brew 安装提示走 `brew uninstall`

## 8. 明确不做

- 不改兄弟仓 `vole` 协议 / 规则引擎 / Helper 安全边界（除非实现阻塞另开 design）
- 不把 hints、白名单做成独立导航项
- 不做 Sparkle / MAS；自更新只走嵌入 sidecar 的 `vole update`
- Touch ID / 更新 / 自卸载不进主侧栏
- 不实现分析内删除、历史撤销

## 9. 风险与缓解

| 风险 | 缓解 |
|---|---|
| 侧栏八项拥挤 | 固定顺序；小幅加宽；必要时缩短标题字重/字号但不改用词 |
| `analyze $HOME` 耗时长 | 扫描中可取消；展示当前路径；允许改根到更小目录 |
| 设置内破坏性操作（更新/自卸载） | 分步：检查/dry-run → 确认 → 执行；默认不 purge oplog |
| Plan 永久删除误触 | `--permanent` 默认关；确认框明示 |

## 10. 验收清单

1. 侧栏八项均可切换，无「即将推出」灰显
2. 净化 / 安装包：空闲 → 扫描 → 勾选 → 确认 → 结果；Helper 未就绪时系统路径跳过语义与 Clean 一致
3. 分析：默认根可扫；钻取进目录与返回；大文件区在有数据时可见；取消有效
4. 历史：有数据时分区列表正确；无数据空态；limit 可调
5. 设置：Touch ID 状态可读且启停反馈真实；更新可 check 并在确认后执行；自卸载 dry-run → 确认删除
6. Clean / 卸载 / 优化 / 状态回归不被破坏
7. 单元测试覆盖：`ShellModule` 顺序与标题；Analyze/History JSON 解码；`PlanModuleKind` 新 case 的 command 与文案键

## 11. 下一步

- 用户审本 spec → `writing-plans` 写实现计划（ShellModule → Plan 扩展 → Analyze → History → Settings 三段 → 测试 / README）
- 实现默认走 inline / task 级 commit；开 PR 与否按完成时 `finishing-a-development-branch` 决策
