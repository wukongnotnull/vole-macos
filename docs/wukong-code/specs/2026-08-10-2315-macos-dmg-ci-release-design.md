# vole-macos：DMG 打包 + CI Release

**日期**：2026-08-10  
**状态**：已批准（用户明确交付物）  
**前置**：[`2026-08-10-2223-macos-notarize-pipeline-design.md`](2026-08-10-2223-macos-notarize-pipeline-design.md)  
**对齐**：兄弟仓 `vole` 的 `release.yml` / `package-release.sh` / `setup-ci-secrets.sh`

## 1. 目标

1. 本机：对已公证并 staple 的 `dist/Vole.app` 产出 `dist/Vole-<version>.dmg`
2. CI：push 标签 `v*` → 签名导出 → 公证 → DMG → GitHub Release 资产
3. 文档：本地命令、标签约定、所需 secrets、勿提交清单

## 2. 标签约定

与 `vole` 一致：**`v0.1.0`**（`v` + semver）。

| 项 | 值 |
|---|---|
| 触发 | `push` tags matching `v*` |
| 版本解析 | `${GITHUB_REF_NAME#v}` → `0.1.0` |
| App 版本源 | 优先 `Vole.app/Contents/Info.plist` 的 `CFBundleShortVersionString`；本地脚本可回退 `pbxproj` 的 `MARKETING_VERSION`（当前 `0.1.0`） |
| 不支持 | `Vole-v*` 前缀（避免两套约定） |

发布前建议：Xcode `MARKETING_VERSION` 与 tag 去掉 `v` 后一致。

## 3. `scripts/package-dmg.sh`

| 项 | 约定 |
|---|---|
| 输入 | `$VOLE_APP` 或默认 `dist/Vole.app`（须已存在） |
| 输出 | `dist/Vole-<version>.dmg`（`UDZO`） |
| 布局 | 低成本 drag-to-Applications：stage 目录内放 `.app` + `Applications` 符号链接 |
| Staple 校验 | `xcrun stapler validate`；失败时默认 **exit 非 0**；`VOLE_DMG_ALLOW_UNSTAPLED=1` 时 WARN 后继续（文档说明） |
| 工具 | `hdiutil create -volname Vole -srcfolder <stage> -ov -format UDZO` |
| 禁止 | 提交 `dist/`、`.dmg`、证书、`.p8`、`signing.env` |

## 4. CI Release 工作流

路径：`.github/workflows/release.yml`

```
checkout vole-macos
checkout vole → ../vole（或 VOLE_SRC）
import Developer ID .p12 → 临时 keychain
archive-and-export.sh
notarize-app.sh          # APPLE_API_KEY_*（无 keychain profile）
package-dmg.sh
zip Vole.app（可选资产）
SHA256SUMS
softprops/action-gh-release 上传 dmg + zip + SHA256SUMS
```

Runner：`macos-latest`。权限：`contents: write`。

缺 secrets 时：**清晰失败**（不 silent skip 公证），以便 release 不被半成品资产污染。与「本机无凭据不 submit」不同——**tag release 必须完整签名+公证**。

### 4.1 兄弟仓 checkout

`embed-vole.sh` 需要 `VOLE_SRC`（默认 `../vole`）。CI 用第二次 `actions/checkout` 把 `wukongnotnull/vole` 放到 `../vole`（相对 workspace），或显式 `VOLE_SRC`。Rust：`dtolnay/rust-toolchain` 或 runner 自带 + 读 `vole/rust-toolchain.toml`。

### 4.2 Secrets（与 vole 对齐）

| Secret | 用途 |
|---|---|
| `APPLE_CERTIFICATE_BASE64` | Developer ID `.p12`（base64） |
| `APPLE_CERTIFICATE_PASSWORD` | p12 密码 |
| `VOLE_CODESIGN_IDENTITY` | 如 `Developer ID Application: Kong Wu (WCYC8XY4V2)` |
| `APPLE_API_KEY_BASE64` | App Store Connect API `.p8`（base64） |
| `APPLE_API_KEY_ID` | Key ID |
| `APPLE_API_ISSUER_ID` | Issuer UUID |

Notary 走 API key（CI 无 login keychain profile）；profile 名仍文档化为 `vole-notary`（本机）。

辅助：`scripts/setup-ci-secrets.sh`（默认 repo `wukongnotnull/vole-macos`），交互写入上表，不落盘 secrets。

## 5. Release 资产

| 文件 | 说明 |
|---|---|
| `Vole-<version>.dmg` | 主分发 |
| `Vole-<version>.zip` | 已公证 staple 的 `.app`（`ditto -c -k --keepParent`） |
| `SHA256SUMS` | 上述两者的 SHA-256 |

## 6. 本机流程（文档）

```bash
bash scripts/check-signing.sh
bash scripts/archive-and-export.sh
bash scripts/notarize-app.sh
bash scripts/package-dmg.sh          # → dist/Vole-0.1.0.dmg
```

CI：

```bash
git tag v0.1.0
git push origin v0.1.0
# → Release 自动创建并挂资产
```

## 7. 勿提交

- `dist/`、`build/`、`*.dmg`、`*.app`（构建产物）
- `scripts/signing.env`、`*.p12`、`AuthKey_*.p8`、任何私钥

## 8. 非目标

- Sparkle / 自动更新频道
- Universal binary 双架构强制（跟随当前 archive 架构）
- 修改 App Store 分发路径
- 在无 Xcode 的 Linux CI 上跑本工作流

## 9. 验收

| 项 | 标准 |
|---|---|
| 本机 DMG | 公证后 `package-dmg.sh` 产出可读挂载的 DMG，含 Applications 链接 |
| 缺 app / 未 staple | 默认非 0 退出并打印下一步 |
| CI 缺 secrets | job 失败并指出缺哪个 secret |
| Tag `v0.1.0` | 在 secrets 齐全时产出 Release 三件套 |
| README | 本地 + CI + secrets 列表 |
