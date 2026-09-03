# Vole macOS · 追上 CLI 2.20：Worktree + Agent

- 日期：2026-09-03 20:53
- 状态：已批准（会话 brainstorming：侧栏 1 · 五态 1 · sidecar 1 · 结构 A · §1–§3 ok）
- 仓库：`vole-macos`
- 产品窗口里程碑：追上 CLI **2.20** 的 Worktree + Agent
- 基线：桌面 `main` @ **0.2.0**（八项侧栏）；内嵌 sidecar 钉 **恰好 `vole` 2.20.0**
- 文档结构：结构 A——一份桌面规格（本文件）+ 日后一份实施计划（本文件不写 plan 正文）
- 本文件授权：写规格；**不开实现**、不 bump 正式 app 版本、不发版、不改兄弟仓 `vole` CLI、不开 PR

## 1. 结论

vole-macos 主侧栏由八项扩为十项：在净化 / 安装包之后插入 **Worktree** 与 **Agent**，分析 / 历史 / 状态仍在最后。两项都走现有 Plan 五态（扩 `PlanModuleKind` + `PlanModuleSession`），不新做专用页、不嵌 TUI。

交互与 CLI 主路径对齐：`--plan --json-stream --plan-out` → 勾选 → `--apply`。默认全不选、默认废纸篓、永久删除开关默认关。文案不宣称可安全删除。Worktree 只管整棵 Git checkout；Agent 不管 checkout。

内嵌 sidecar **恰好 2.20.0**。运行时若 `--version` 不是 `2.20.x`，这两项标为不可用，不假装能扫。不 bump `schema_version`。本文件不批准发版。

本文件**覆盖** [`1454`](2026-08-09-1454-app-nav-cli-parity-design.md) §2 侧栏八项顺序：改为十项，插入位在安装包与分析之间。

## 2. 已锁定决策

| 项 | 结论 |
|---|---|
| 仓库 | **只动 `vole-macos`**；`vole` CLI 仓零改、不发 CLI 版 |
| 北极星 | 窗口补齐 CLI 已有的 Worktree / Agent，内嵌 sidecar **2.20.0** |
| 侧栏 | **1**：主栏各加一项。顺序：清理 → 卸载 → 优化 → 净化 → 安装包 → **Worktree → Agent** → 分析 → 历史 → 状态 |
| 交互 | **1**：复用 Plan 五态；默认全不选；废纸篓；不宣称可安全删 |
| sidecar | **1**：本里程碑内嵌 `vole` **恰好 2.20.0** |
| 文档结构 | **结构 A**：一份桌面规格（本文件）+ 日后一份实施计划 |
| 删除对象 | Worktree = 整棵 checkout only；Agent ≠ checkout（容器 / 会话 / 缓存残留） |
| 默认勾选 | **全不选**（与 CLI `worktree` / `agent` 同；与现有净化 / 安装包扫完全选相反） |
| 去向 | 默认废纸篓；永久删除开关默认关（对齐净化 / 安装包） |
| 协议 | 只消费现有 Plan JSON / NDJSON；**不 bump `schema_version`** |
| 架构 | 扩现有 `PlanModuleKind` + `PlanModuleSession`；不抽象第三套框架；不嵌 ratatui |
| 锁 | sidecar `try_lock_config("worktree")` / `try_lock_config("agent")`；UI 展示真错误 |
| Helper | 与现有 Plan 模块相同：用户域废纸篓；系统路径经既有特权通道，未就绪则跳过 |
| 版本门控 | 启动读 sidecar `--version`；不是 `2.20.x` 则 Worktree / Agent 不可用 |
| 中文标题 | 侧栏标题即为 **Worktree** / **Agent**（不用「工作树」「代理」） |
| 数字键 | 不要求对齐 CLI Home；桌面是点选 |
| 本文件授权 | 写规格；不开实现、不 bump 正式 app 版本、不发版、不改 CLI 仓、不开 PR |

## 3. 目标与非目标

### 3.1 北极星

窗口补齐 CLI 已有的 Worktree / Agent，内嵌 sidecar **2.20.0**，让桌面成为与 CLI 2.20 同能力面的主流入口。

### 3.2 必做

- 侧栏十项：清理 → 卸载 → 优化 → 净化 → 安装包 → **Worktree → Agent** → 分析 → 历史 → 状态
- 两项都走现有 Plan 五态：`worktree|agent --plan --json-stream --plan-out` → 勾选 → `--apply`
- 默认全不选；默认废纸篓；永久删除开关默认关
- 文案不宣称「可安全删除」；Worktree 只管 checkout，Agent 不管 checkout
- 内嵌 `vole` 钉 **恰好 2.20.0**
- 不 bump `schema_version`

### 3.3 明确不做

- 再开 vole CLI 新功能
- 冲 Homebrew core
- analyze 在桌面里删除文件
- 新做专用页或嵌 TUI
- 本文件批准 vole-macos 发版（发版另问；未获确认不打版 tag）
- 本文件 bump 正式 app / marketing 版本（现 **0.2.0** 保持到发版确认）
- 改兄弟仓协议、规则引擎、或新开 SMAppService API
- 第二条删除路径（App 不得对用户勾选项走 `FileManager` 直删）
- 冲 Mac App Store；不改现有公证语义

### 3.4 成功标准

十项侧栏能走完 Worktree / Agent 主路径。无 sidecar 2.20 时不得把这两项标成已可用。

## 4. 侧栏、五态与 sidecar

### 4.1 `ShellModule` 顺序与文案

新增 cases：`worktree`、`agent`。`CaseIterable` 顺序与下表一致。

| 顺序 | `ShellModule` | 标题 | 空闲说明（侧栏不展示长文案；进模块后用） | SF Symbol |
|---|---|---|---|---|
| 1 | `clean` | 清理 | 不改 | `sparkles` |
| 2 | `uninstall` | 卸载 | 不改 | `trash` |
| 3 | `optimize` | 优化 | 不改 | `gauge` |
| 4 | `purge` | 净化 | 不改 | `flame` |
| 5 | `installer` | 安装包 | 不改 | `shippingbox` |
| 6 | `worktree` | Worktree | 清理遗留的 Git worktree（整棵 checkout） | `arrow.triangle.branch` |
| 7 | `agent` | Agent | 清理 Agent 容器 / 会话 / 缓存残留 | `cpu` |
| 8 | `analyze` | 分析 | 不改 | `chart.pie` |
| 9 | `history` | 历史 | 不改 | `clock` |
| 10 | `status` | 状态 | 不改 | `chart.bar` |

前五项与分析 / 历史 / 状态的标题、图标、路由不改。`worktree` / `agent` 图标不与状态 `chart.bar`、净化 `flame`、分析 `chart.pie` 撞。

侧栏沿用现有 `SidebarView` 纵向滚动。十项标题（含 Worktree / Agent）须完整可见、不得截成省略号；若现有最小宽度不够，加宽到刚好完整可见为止，不改用词。不强制抬高最小窗口高度。

### 4.2 可用性

- 清理 / 卸载 / 优化 / 净化 / 安装包 / 分析 / 历史 / 状态：保持现有 `isAvailable == true`，不受本里程碑版本门控。
- `worktree` / `agent`：仅当内嵌 sidecar `--version` 解析出的 SemVer **主.次 = 2.20**（即 `2.20.x`）时可用。版本字符串由 sidecar 探测注入（测试注入假版本）；禁止把这两项的 `isAvailable` 写成无参恒 `true`。
- 解析规则：取 `--version` 首行中第一个 `X.Y.Z`（兼容 `vole 2.20.0` 与 `vole-cli 2.20.0`）；带预发布后缀仍按 `X.Y` 判断。解析失败或不是 `2.20.x` → 两项不可用。
- 不可用时：侧栏灰显；点击不启动扫描、不调旧二进制硬扫；提示需要内嵌 vole 2.20。不得写「即将推出」来掩盖版本不匹配。

### 4.3 `ShellView` 路由

| 模块 | 宿主 |
|---|---|
| worktree / agent | `PlanModuleRootView` + `PlanModuleSession`（扩展 `PlanModuleKind`） |
| 既有八项 | 不变 |

### 4.4 五态（两项同一套）

扩展 `PlanModuleKind`：`worktree`、`agent`。`command` 分别为 `"worktree"` / `"agent"`。`supportsPermanentDelete == true`（与净化 / 安装包同形）。

现有 `PlanModuleSession` 在扫完后把 `selectedIDs` 设为全部条目。本里程碑为 kind 增加明确开关：

- `selectsAllCandidatesByDefault`：`uninstall` / `optimize` / `purge` / `installer` 仍为 `true`（不改既有模块默认）
- `worktree` / `agent` 为 `false`：进入候选页时 **0 条预勾选**

五态：

1. **空闲**：一句风险说明（不宣称可安全删）+ 开始扫描
2. **扫描**：`worktree|agent --plan --json-stream --plan-out`；可取消（映射 sidecar 中断语义）
3. **候选**：列表勾选，**默认全不选**；展示体积（sidecar 有则显示，全 0 也诚实，不因此改成「看起来可删」）。保留现有「全选 / 全不选」按钮，但 **不**提供「全选并跳过确认」的合并动作
4. **确认**：写明废纸篓；永久删除开关默认关；开启时确认文案必须明示永久删除、不可从废纸篓恢复
5. **结果**：成功 / 跳过 / 失败用 sidecar 真值，不假成功

CLI apply：`worktree|agent --apply <plan> --json-stream`；开关开启时追加 `--permanent`（与现有 `PlanModuleSession.applyArguments` 同形）。

互斥：沿用 per-command sidecar 锁（`try_lock_config("worktree")` / `try_lock_config("agent")`）。同一时刻只能跑一个 worktree **或** 一个 agent（各锁各的；不与净化共用同一把锁）。UI 展示真实锁错误，不假成功。

特权：用户域走废纸篓；系统路径规则与现有 Plan 模块相同（Helper 未就绪则跳过并说明）。不为本两项新开 SMAppService API。

### 4.5 中文文案（田鼠工坊语气，钉死用词）

| 键 | Worktree | Agent |
|---|---|---|
| `title` | Worktree | Agent |
| `idleEyebrow` | Worktree · 工作树 | Agent · 代理残留 |
| `idleHeadline` | 翻出被遗忘的 checkout | 翻出 Agent 留下的容器 |
| `idleCaption` | 扫描遗留的 Git worktree。将整棵 checkout 送进废纸篓。**不宣称可安全删除。** | 扫描 Agent 容器、会话与缓存残留（不是 Git checkout）。默认进废纸篓。**不宣称可安全删除。** |
| `candidatesTitle` | 挑要移走的 checkout | 挑要移走的残留 |
| `primaryActionTitle` | 清理所选 | 清理所选 |
| `confirmButton` | 确认清理 | 确认清理 |
| `resultTitle` | Worktree 清理完成 | Agent 清理完成 |
| 确认底文 | 将删除已选的整棵 Git checkout（默认进废纸篓；需管理员权限的文件经 root权限助手，未就绪则跳过）。不宣称可安全删除。 | 将删除已选的 Agent 容器 / 会话 / 缓存残留（默认进废纸篓；需管理员权限的文件经 root权限助手，未就绪则跳过）。不宣称可安全删除。 |

空闲区必须出现「不宣称可安全删除」。不得用「放心删」「已过期」「可安全移除」等正向承诺。

### 4.6 硬边界（UI 不得绕过）

去重与排除在 CLI 内执行；UI 不另开删除通道、不在客户端重写认领规则。

- **Worktree**：不列出主工作区、当前 cwd 所在 worktree；不删产物-only（那是净化等命令的事）
- **Agent**：不列出已被 `worktree` 认领的 checkout；不把整个 `$HOME` 当无界根深扫
- 两条命令不得对同一路径双删（同一规范化绝对路径只许一个命令认领：checkout 归 worktree，其余归 agent）

若 sidecar 因硬排除 / 锁 / 过期拒绝删除，结果页按跳过或失败展示，不当成功。

### 4.7 sidecar

- 内嵌 `vole` **恰好 2.20.0**（与已发 CLI 对齐）。构建来源仍是兄弟仓 `../vole`（可 `VOLE_SRC` 覆盖），但本里程碑嵌入产物的 `--version` 必须是 `2.20.0`，不得把未发布的更新 CLI 带进窗口包
- 启动时校验 `--version`；不是 `2.20.x` 则两项标为不可用，不调旧二进制硬扫
- 不改 `schema_version`（现为 `1`）；只消费现有 Plan JSON / NDJSON
- CLI 仓零改。实现时若发现协议缺字段：停下来另开 design，本文件不授权 bump `schema_version`

### 4.8 文档与分发（实现阶段，不阻塞本规格）

- README 五语（`README.md` / `README.zh-CN.md` / `README.zh-TW.md` / `README.ja.md` / `README.ko.md`）在实现时把侧栏能力表加上 Worktree / Agent，不得预写成「已随 0.2.0 发布」
- 截图在实现后更新，不阻塞本规格
- 本波不冲 Mac App Store，不改公证语义

## 5. 架构与风险

```text
vole-macos UI     侧栏 + Plan 五态（扩 PlanModuleKind）
sidecar vole      恰好 2.20.0：worktree / agent plan+apply
vole-core         删除漏斗仍在 CLI 内；app 不另写 rm
Helper            仅既有特权通道；不为本两项新开 SMAppService API
```

- 扩现有 `PlanModuleKind` + `PlanModuleSession`，不抽象第三套框架，不嵌 ratatui。
- CLI 仓零改，除非实现时发现协议缺字段——那时停下来另开 design，不在本规格授权 bump `schema_version`。
- 删除只走 sidecar apply + 既有 Helper 分区；禁止第二条删除路径。

### 5.1 风险

1. **误删 checkout / 会话**：默认全不选 + 确认文案写明不宣称可安全删 + CLI 硬排除。UI 不提供「全选并跳过确认」。
2. **sidecar 不是 2.20**：两项显示不可用，并提示需要内嵌 2.20，不调旧二进制硬扫。
3. **与净化抢锁**：per-command 锁；同时只能跑一个 worktree 或一个 agent。净化用自己的锁。UI 展示真实锁错误。
4. **体积全 0**：诚实显示；不因此改成「看起来可删」。

## 6. 验收

1. 侧栏十项顺序与 §4.1 一致；点 Worktree / Agent 能走完五态。
2. 打开候选页时 **0 条预勾选**。
3. 无 `2.20.x` sidecar 时两项不可用（灰显、不扫描）。
4. 内嵌 sidecar `--version` 为 **2.20.0**。
5. 不出现第二条删除路径；`schema_version` 仍为 `1`。
6. 永久删除开关默认关；开启时确认文案明示永久删除。
7. Helper 未就绪时系统路径跳过语义与净化 / 安装包一致。
8. 清理 / 卸载 / 优化 / 净化 / 安装包 / 分析 / 历史 / 状态回归不被破坏（含既有模块扫完仍默认全选）。
9. README 五语在实现时更新；未获用户确认前不打 vole-macos 版 tag、不建 GitHub Release。
10. 单元测试覆盖：`ShellModule` 十项顺序与标题；`isAvailable` 在非 `2.20.x` 时对 worktree/agent 为 false；`PlanModuleKind` 新 case 的 `command`、`selectsAllCandidatesByDefault == false`、`supportsPermanentDelete`、文案键含「不宣称可安全删除」。

## 7. 与既有文档关系

| 文档 | 关系 |
|---|---|
| [`2026-08-09-1454-app-nav-cli-parity-design.md`](2026-08-09-1454-app-nav-cli-parity-design.md) | 八项侧栏与净化 / 安装包五态的权威规格。本文件**覆盖**其 §2 侧栏顺序（八→十，插入 Worktree / Agent）。分析不删文件、协议不 bump、不嵌 TUI 等约束继承。 |
| [`2026-08-08-2245-vole-ui-shell-clean-design.md`](2026-08-08-2245-vole-ui-shell-clean-design.md) | 壳与「田鼠工坊」视觉基线。2245 曾把分析 / 历史放更多；已被 1454 改入主栏。本文件不改品牌 token，只扩侧栏两项。 |
| [`2026-07-30-2328-desktop-clean-mvp-design.md`](2026-07-30-2328-desktop-clean-mvp-design.md) | sidecar 编排、五态、Plan TTL / TOCTOU 的桌面起点。本里程碑仍 100% 走内嵌 `vole`，不在 App 复刻删除逻辑。 |
| [`2026-08-08-1822-smappservice-privileged-helper-design.md`](2026-08-08-1822-smappservice-privileged-helper-design.md) | 系统路径经既有 Helper。本文件不新开特权 API。 |
| 兄弟仓 [`2026-08-14-0228-worktree-design.md`](../../../../vole/docs/wukong-code/specs/2026-08-14-0228-worktree-design.md)（[GitHub](https://github.com/wukongnotnull/vole/blob/main/docs/wukong-code/specs/2026-08-14-0228-worktree-design.md)） | CLI `worktree` 契约：整棵 checkout、默认全不选、不宣称可安全删、硬排除主工作区与 cwd。桌面只消费该命令，不扩 worktree 管非 checkout。 |
| 兄弟仓 [`2026-09-02-1530-v3-cli-generation-design.md`](../../../../vole/docs/wukong-code/specs/2026-09-02-1530-v3-cli-generation-design.md)（[GitHub](https://github.com/wukongnotnull/vole/blob/main/docs/wukong-code/specs/2026-09-02-1530-v3-cli-generation-design.md)） | CLI 产品 v3 / `vole agent`（Home 第 7 项）与路径去重。该文件写明桌面「本代际不排期」。本文件是那条放下的轨 1 的桌面规格；CLI 契约（Agent ≠ checkout、默认全不选、废纸篓、不 bump schema）原样消费。 |

## 8. 下一步

本文件已写入并提交，**待用户 review 本规格文件**。

用户确认规格无需再改之后，再按 writing-plans 写**一份**实施计划（结构 A：Worktree / Agent 五态 + sidecar 升 2.20.0 同一计划）。此刻：

- **不写** plan 正文
- **不开** 实现
- **不 bump** 正式 app 版本
- **不发版**
- **不开** PR
- **不改** 兄弟仓 `vole` CLI
