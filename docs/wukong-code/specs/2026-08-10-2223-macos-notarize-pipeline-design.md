# vole-macos：Archive → Notarize → Staple 管线

**日期**：2026-08-10  
**状态**：已批准（用户明确交付物）  
**Team**：`WCYC8XY4V2`  
**Identity**：`Developer ID Application: Kong Wu (WCYC8XY4V2)`  
**Notary profile**：`vole-notary`（与兄弟仓 `vole` 共用）

## 1. 目标

为 `Vole.app` 提供本机可重复的：

1. `xcodebuild archive` + `exportArchive`（Developer ID）
2. `notarytool submit --wait`
3. `stapler staple` + `spctl` 校验

不要求本轮交付 DMG；CI **不得**因缺少公证凭据而失败。

## 2. 验收标准

| 项 | 标准 |
|---|---|
| 凭据一次配置 | 复用 `vole` 的 `scripts/setup-notary-profile.sh`，profile 名 `vole-notary`；vole-macos **不**复制一套并行 auth |
| 无 profile | `notarize-app.sh` / `check-signing.sh` 清晰退出（非 0）并打印下一步；不真正 submit |
| 有 identity + profile | 三步脚本可产出已 staple 的 `Vole.app` |
| Cursor 沙箱 | 文档明确：钥匙串/私钥须在 **终端.app**（或 iTerm）跑，勿依赖 Cursor 内置终端 |
| CI | 不把真实公证当作 required check；脚本可在无凭据环境 dry-check |

## 3. 脚本布局

均在 `scripts/`：

| 路径 | 职责 |
|---|---|
| `scripts/ExportOptions.plist` | `method=developer-id`，`teamID=WCYC8XY4V2` |
| `scripts/check-signing.sh` | 查 Developer ID + `vole-notary` profile；缺则 FAIL/SKIP 说明；可 source 本仓 `signing.env` 或兄弟仓 vole 的 `signing.env` |
| `scripts/archive-and-export.sh` | Archive scheme `vole-macos` → export → `dist/Vole.app`（可覆盖路径） |
| `scripts/notarize-app.sh` | zip → `notarytool submit --keychain-profile vole-notary --wait` → staple → `spctl` |

可选后续：`package-dmg.sh`（本设计范围外）。

## 4. 凭据与配置

- **一次人工**：在终端.app 于 `vole` 仓执行  
  `bash scripts/setup-notary-profile.sh`（或 `--api-key …`）  
  写入 login keychain 的 `vole-notary`。
- vole-macos 可选 `scripts/signing.env`（gitignore）：

```bash
export VOLE_CODESIGN_IDENTITY="Developer ID Application: Kong Wu (WCYC8XY4V2)"
export VOLE_NOTARY_PROFILE="vole-notary"
```

若本仓无 `signing.env`，脚本尝试 `../vole/scripts/signing.env`，再回退默认 identity / `vole-notary`。

## 5. 推荐本机流程（3 命令）

```bash
# 一次性（兄弟仓 vole）
cd ../vole && bash scripts/setup-notary-profile.sh

cd ../vole-macos
bash scripts/check-signing.sh
bash scripts/archive-and-export.sh
bash scripts/notarize-app.sh
```

## 5.1 Hardened Runtime（`vole-cli` sidecar）

Apple 公证要求 bundle 内**每个**可执行文件启用 Hardened Runtime。App / Helper 由 Xcode `ENABLE_HARDENED_RUNTIME=YES` 覆盖；`Contents/MacOS/vole-cli` 由 `embed-vole.sh` 拷贝进来，`exportArchive` 对其签名时**不会**自动带 `--options runtime`，会导致 notary `Invalid`：

> The executable does not have the hardened runtime enabled. (`…/Contents/MacOS/vole-cli`)

缓解：`archive-and-export.sh` 在 export 后调用 `ensure_nested_hardened_runtime`（sidecar → 再密封外层 `.app`）；`notarize-app.sh` 在 submit 前 `require_app_hardened_runtime` 失败即退出。

## 6. 沙箱与失败语义

- `HOME` 落在 `/var/folders/…`（Cursor 沙箱）时打印 WARN，指引改用终端.app。
- `check-signing.sh`：无 identity → exit 1；有 identity 无 profile → exit 0 但标注 SKIP notarization（与 vole 一致，便于「仅检查签名」）；`notarize-app.sh` 无 profile → exit 3，绝不 submit。
- `archive-and-export.sh`：无 Xcode / 失败则非 0；不调用 notary。

## 7. 非目标

- 不改 Xcode 工程签名设置为 Automatic App Store
- 不强制 CI 注入 p12 / API key（可后续对齐 vole release workflow）
- 不做 DMG / Sparkle 喂料
