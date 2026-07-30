# Vole macOS Desktop：Clean MVP 设计

- 日期：2026-07-30
- 状态：已批准（对话评审 §1–§5）
- 仓库：`vole-macos`（另仓）
- 依赖：兄弟仓 [`vole`](https://github.com/wukongnotnull/vole) CLI（产品 v2 已成熟，包 ≥ `1.2.0`）
- 依据：`vole` 仓 `docs/wukong-code/specs/2026-07-29-rust-rewrite-design.md` §5.6；`docs/protocol.md`（冻结 `schema_version = 1`）；`docs/wukong-code/specs/2026-07-30-1900-v2-product-goals-design.md`（SwiftUI 另仓下一轨）

## 1. 结论

在 `vole-macos` 交付**本机可跑**的 SwiftUI 原型：仅暴露 **`clean`** 的 plan → 勾选 → apply（默认废纸篓）。编排 100% 走 Bundle 内嵌 `vole` sidecar，不复刻清理逻辑，不改冻结协议。

## 2. 已锁定决策

| 项 | 结论 |
|---|---|
| MVP 范围 | 仅 `clean` |
| Sidecar | Bundle 内嵌 `vole` + rules |
| 交付目标 | 本机可跑原型；ad-hoc / 开发签名即可 |
| 构建来源 | Xcode Run Script 对兄弟仓 `../vole`（可 `VOLE_SRC` 覆盖）`cargo build -p vole-cli --release` |
| FDA | 最小提示：权限失败时 alert +「打开系统设置」 |
| 架构 | SwiftUI 薄壳 + 短生命周期 `Process` sidecar（方案 1） |
| 许可证 | GPL-3.0-only（与 CLI 一致） |
| 协议 | 只消费冻结 NDJSON / Plan / Report；`schema_version == 1` |
| CLI 改动 | 本里程碑默认 **零改** `vole` 仓 |

## 3. 目标与成功标准

### 3.1 目标

对用户提供可勾选的清理向导；所有扫描与删除由内嵌 `vole clean` 完成。

### 3.2 成功标准

1. Xcode Run 能启动 App；Bundle 内含本机构建的 `vole` + rules
2. 「扫描」执行 `vole clean --plan --json-stream`，进度可见；结束后列表可勾选
3. 「清理」写出含勾选条目的 Plan，再 `vole clean --apply <plan>`；展示 Report 摘要
4. 取消扫描可终止 sidecar 进程
5. 权限不足时给出 FDA 最小提示（可打开系统设置）
6. 不 bump / 不破坏 `schema_version`

### 3.3 明确不做（本里程碑）

`status` / `analyze` / `uninstall` / `optimize` / `history` · `--permanent` · Developer ID / 公证 · 自动更新 · Sparkle · 完整首启 onboarding · FFI · daemon · SMAppService / sudo · 精致品牌 UI · 改 `vole` 协议

## 4. 架构与进程边界

```
┌─────────────────────────────┐
│  Vole.app (SwiftUI)         │
│  CleanSession / UI          │
│         │                   │
│         ▼                   │
│  SidecarRunner (Process)    │
│    stdin 关闭 / terminate   │
│    stdout → NDJSON 解析     │
│    stderr → 诊断日志        │
└───────────┬─────────────────┘
            │ exec
            ▼
┌─────────────────────────────┐
│  Contents/MacOS/vole        │
│  + Contents/share/vole/rules│
└─────────────────────────────┘
```

### 4.1 原则

1. **进程边界**：不 link Rust；不 daemon；每次 plan / apply 各起短生命周期进程
2. **协议**：只消费 `vole` 仓冻结的 `docs/protocol.md`；可选启动时 `vole --version` 自检
3. **路径**：sidecar 固定 Bundle 内相对路径，**不用** PATH / Homebrew 上的 `vole`
4. **规则**：优先依赖 CLI 相对布局发现（`MacOS/vole` → `../share/vole/rules`）；失败则设 `VOLE_RULES_DIR`
5. **Plan 落盘**：App 沙盒临时目录（如 Caches）；勾选 = 过滤 `entries` 后写新文件再 apply；**不**发明「已批准」信任字段
6. **威胁模型**：apply 安全闸口、TTL、TOCTOU 全在 `vole` 内；App 只做 UI 与进程编排
7. **取消**：扫描 / apply 中均可 terminate；apply 取消须标明「可能已部分清理」
8. **仓边界**：实现与文档主战场在 `vole-macos`；本里程碑不改 CLI

### 4.2 命令约定

| 阶段 | 命令 |
|---|---|
| Plan | `vole clean --plan --json-stream`（可选同时 `--plan-out` 落全量 plan） |
| Apply | `vole clean --apply <filtered-plan.json>`（默认废纸篓，不加 `--permanent`） |

App 维护内存中的候选列表（来自 `candidate` 事件或 plan JSON）；用户勾选后序列化子集 `Plan`（保留原 `schema_version` / `created_at` / `ttl_secs` / 选中 `entries`）。

## 5. UI 流与交互

### 5.1 主流程（单窗五态）

```
[空闲] → 扫描中 → [候选列表] → 清理中 → [结果]
              ↑取消              ↑返回重扫
```

| 状态 | 界面要点 |
|---|---|
| 空闲 | 标题「清理」+ 简短说明（移到废纸篓）+「扫描」；可显示内嵌 `vole` 版本 |
| 扫描中 | `scanned` + `current`；「取消」 |
| 候选列表 | 可勾选行（label、可读大小、rule_id）；全选/全不选；「已选 N · 共 X」+「清理到废纸篓」；可「重新扫描」 |
| 清理中 | apply 进度或 indeterminate；「取消」 |
| 结果 | Report：`succeeded` / `skipped` / `failed`、`trashed_bytes`；「完成」回空闲 |

### 5.2 交互细节

1. 默认**全选**可清理条目（无 `skip_reason`）；有 `skip_reason` 的不可勾或放入「已跳过」区
2. 清理前确认对话框：「将把已选项目移到废纸篓」
3. FDA：权限相关失败 → alert + 打开 Privacy FDA 设置
4. Plan TTL：超过 `created_at + ttl_secs`（默认 900）禁止 apply，提示重扫
5. 本版无侧边栏、无多命令 Tab、无 permanent 开关
6. 视觉：系统原生 SwiftUI，原型够用即可

## 6. 构建、嵌入与工程结构

### 6.1 Bundle 布局

```
Vole.app/Contents/
  MacOS/
    vole-macos          # SwiftUI 主程序
    vole                # sidecar
  share/vole/rules/     # 自 VOLE_SRC/data/rules 拷贝 *.toml
```

### 6.2 Xcode Run Script

1. `VOLE_SRC` 默认 `$(SRCROOT)/../vole`，可环境变量覆盖
2. `cargo build -p vole-cli --release`（arch 跟随当前机）
3. copy `target/release/vole` → `Contents/MacOS/vole`
4. rsync rules → `Contents/share/vole/rules/`
5. 缺仓或缺 cargo → **fail build** 并打印路径（不静默跳过）
6. 脚本落盘：`scripts/embed-vole.sh`，供 Build Phase 调用

### 6.3 建议目录

```
vole-macos/
  README.md
  LICENSE                 # GPL-3.0
  docs/wukong-code/specs/
  docs/wukong-code/plans/
  scripts/embed-vole.sh
  vole-macos/
    Sidecar/              # Runner + NDJSON
    Clean/                # Session / Views
    Support/              # FDA、格式化
  vole-macos.xcodeproj
```

### 6.4 版本与签名

- App 营销版本先 `0.1.0`；sidecar 以 `vole --version` 为准并在 UI 展示
- 本里程碑：ad-hoc / 开发签名；不做公证流水线
- 两仓并列本地路径；不强制 git submodule

### 6.5 测试（原型级）

- 单元：NDJSON 样例解码、Plan 子集序列化 round-trip
- 手动：扫描 → 勾选 → 废纸篓可见
- 本里程碑不做 UI 自动化门禁

## 7. 风险与缓解

| 风险 | 缓解 |
|---|---|
| 首次 cargo 慢 / 缺 toolchain | README 写前置；Run Script 失败即停 |
| Bundle 内 rules 发现失败 | 回退 `VOLE_RULES_DIR` |
| ad-hoc 签名导致 FDA 授权不稳 | 原型接受；文档注明；正式分发另里程碑 |
| Plan TTL 过期 | UI 禁止 apply + 重扫 |
| apply 中途取消 | 文案标明可能部分清理 |
| 列表过大卡顿 | 先用 List；按 rule 分组不阻塞 MVP |

## 8. 验收清单（人工）

1. 两仓并列 → Xcode Run 成功
2. 扫描出候选 → 勾选子集 → 废纸篓可见对应项
3. 取消扫描立刻停下
4. 无 FDA 时有提示并可打开设置

## 9. 文档与下一步

- 本设计：`docs/wukong-code/specs/2026-07-30-2328-desktop-clean-mvp-design.md`
- 实施计划：用户审完本 spec 后，用 writing-plans 写到 `docs/wukong-code/plans/`
- `vole` 仓 README「下一轨」外链：可选后续小 PR，不阻塞本仓实现
