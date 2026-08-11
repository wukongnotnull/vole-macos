# Universal Binary Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use wukong-code:subagent-driven-development (recommended) or wukong-code:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Release/CI 产出的 `Vole-*.dmg` / `.zip` 内主程序、`VolePrivilegedHelper`、`vole-cli` 均为 `arm64 + x86_64` Universal binary。

**Architecture:** Release 路径强制双架构：Xcode archive 设 `ARCHS=arm64 x86_64` + `ONLY_ACTIVE_ARCH=NO`；`embed-vole.sh` 在 Release（或 `VOLE_UNIVERSAL=1`）时分别 cargo 交叉编译两 target 再 `lipo`；export 后用 `lipo -archs` 门禁失败即退出。Debug 本机构建保持单架构以加快迭代。

**Tech Stack:** bash、`lipo`、`cargo`（`aarch64-apple-darwin` / `x86_64-apple-darwin`）、`xcodebuild`、GitHub Actions `macos-latest`

## Global Constraints

- 仍发**一个** Universal DMG（不拆两个架构资产）
- Debug / 日常 `xcodebuild` 本机迭代：**不强制** Universal（除非 `VOLE_UNIVERSAL=1`）
- sidecar 嵌入名保持 `Contents/MacOS/vole-cli`（不改回 `vole`）
- 公证 / Hardened Runtime 流程不变；Universal 变更后仍须 `ensure_nested_hardened_runtime`
- 兄弟仓 Rust toolchain：`1.97.1`，targets 已含 `aarch64-apple-darwin` 与 `x86_64-apple-darwin`（`vole/rust-toolchain.toml`）
- 不改 App Store 分发路径；不引入 Sparkle

## File Structure

| File | Responsibility |
|------|----------------|
| `scripts/lib-universal.sh` | `macho_has_arches` / `require_macho_arches` / `require_app_universal`（可被 archive 与本地检查复用） |
| `scripts/embed-vole.sh` | Release 或 `VOLE_UNIVERSAL=1` 时双 target cargo + lipo；Debug 单架构 |
| `scripts/archive-and-export.sh` | Release archive 传入 `ARCHS` / `ONLY_ACTIVE_ARCH`；export 后调用 `require_app_universal` |
| `.github/workflows/release.yml` | 安装双 apple-darwin Rust targets |
| `docs/wukong-code/specs/2026-08-10-2315-macos-dmg-ci-release-design.md` | 非目标 → 目标：Universal |
| `README.md` / `README.zh-CN.md` | 安装说明注明 Universal（Apple Silicon + Intel） |

---

### Task 1: Universal 检查库 + embed-vole 双架构

**Files:**
- Create: `scripts/lib-universal.sh`
- Modify: `scripts/embed-vole.sh`
- Test: 本机 `bash -n` + 用 `VOLE_UNIVERSAL=1` 跑 embed（或最小 lipo 自检）

**Interfaces:**
- Consumes: Xcode 环境变量 `CONFIGURATION`、`SRCROOT`、`TARGET_BUILD_DIR`、`CONTENTS_FOLDER_PATH`、`PRODUCT_NAME`；可选 `VOLE_SRC`、`VOLE_UNIVERSAL`、`CARGO`
- Produces:
  - `macho_has_arches <bin> <arch> [<arch>...]` → 0/1
  - `require_macho_arches <bin> <arch> [<arch>...]` → 失败非 0
  - `require_app_universal <app>` → 检查 `Vole`、`vole-cli`、`VolePrivilegedHelper` 均含 `arm64` 与 `x86_64`
  - embed 后 `Contents/MacOS/vole-cli` 在 Universal 模式下为 fat binary

- [ ] **Step 1: 写失败用例（门禁函数契约）**

创建临时验证脚本思路（实现后可删，或保留为注释中的手工命令）：先确认当前单架构 sidecar **不满足**双架构：

```bash
# 若已有本机构建的 app：
lipo -archs dist/Vole.app/Contents/MacOS/vole-cli
# Expected before fix: 仅 arm64 或仅 x86_64（一行一个架构）
```

- [ ] **Step 2: 创建 `scripts/lib-universal.sh`**

```bash
#!/usr/bin/env bash
# shellcheck shell=bash
# Shared Universal (fat) Mach-O checks for vole-macos release.

macho_has_arches() {
  local bin="$1"
  shift
  local archs needed
  [[ -f "$bin" ]] || return 1
  archs="$(lipo -archs "$bin" 2>/dev/null || true)"
  [[ -n "$archs" ]] || return 1
  for needed in "$@"; do
    # word match: lipo prints e.g. "x86_64 arm64"
    echo "$archs" | tr ' ' '\n' | grep -qx "$needed" || return 1
  done
  return 0
}

require_macho_arches() {
  local bin="$1"
  shift
  local archs
  if macho_has_arches "$bin" "$@"; then
    archs="$(lipo -archs "$bin")"
    echo "OK: universal arches ($archs) — $bin"
    return 0
  fi
  archs="$(lipo -archs "$bin" 2>/dev/null || echo "<unreadable>")"
  echo "FAIL: expected arches [$*], got [$archs] — $bin" >&2
  return 1
}

require_app_universal() {
  local app="$1"
  local macos="$app/Contents/MacOS"
  local failed=0
  local name

  [[ -d "$macos" ]] || {
    echo "require_app_universal: missing $macos" >&2
    return 2
  }

  for name in Vole vole-cli VolePrivilegedHelper; do
    if [[ ! -f "$macos/$name" ]]; then
      echo "FAIL: missing executable — $macos/$name" >&2
      failed=1
      continue
    fi
    require_macho_arches "$macos/$name" arm64 x86_64 || failed=1
  done

  if [[ "$failed" -ne 0 ]]; then
    echo "Release app must be Universal (arm64 + x86_64) for all MacOS executables." >&2
    return 1
  fi
  return 0
}
```

- [ ] **Step 3: 改 `scripts/embed-vole.sh` — Universal 构建分支**

在现有 `cargo build -p vole-cli --release` 单架构路径上，按配置分流。关键逻辑（替换「building vole-cli」那一段）：

```bash
# shellcheck source=lib-universal.sh
# (optional source only needed if embed self-checks; lipo 后可本地校验)

CONFIGURATION="${CONFIGURATION:-Debug}"
want_universal=0
if [[ "$CONFIGURATION" == "Release" || "${VOLE_UNIVERSAL:-0}" == "1" ]]; then
  want_universal=1
fi

echo "note: building vole-cli --release from $VOLE_SRC (cargo=$CARGO, universal=$want_universal)"
(
  cd "$VOLE_SRC"
  if [[ "$want_universal" -eq 1 ]]; then
    rustup target add aarch64-apple-darwin x86_64-apple-darwin >/dev/null 2>&1 || true
    "$CARGO" build -p vole-cli --release --target aarch64-apple-darwin
    "$CARGO" build -p vole-cli --release --target x86_64-apple-darwin
  else
    "$CARGO" build -p vole-cli --release
  fi
)

if [[ "$want_universal" -eq 1 ]]; then
  ARM_BIN="$VOLE_SRC/target/aarch64-apple-darwin/release/vole"
  X86_BIN="$VOLE_SRC/target/x86_64-apple-darwin/release/vole"
  [[ -x "$ARM_BIN" && -x "$X86_BIN" ]] || {
    echo "error: missing per-arch vole binaries for lipo" >&2
    echo "  expected: $ARM_BIN" >&2
    echo "  expected: $X86_BIN" >&2
    exit 1
  }
  mkdir -p "$MACOS_DIR"
  rm -f "$MACOS_DIR/vole" "$MACOS_DIR/$SIDECAR_NAME"
  lipo -create -output "$MACOS_DIR/$SIDECAR_NAME" "$ARM_BIN" "$X86_BIN"
  chmod 755 "$MACOS_DIR/$SIDECAR_NAME"
  # verify fat
  archs="$(lipo -archs "$MACOS_DIR/$SIDECAR_NAME")"
  echo "note: lipo vole-cli arches: $archs"
  echo "$archs" | tr ' ' '\n' | grep -qx arm64
  echo "$archs" | tr ' ' '\n' | grep -qx x86_64
else
  VOLE_BIN="$VOLE_SRC/target/release/vole"
  [[ -x "$VOLE_BIN" ]] || { echo "error: expected executable at $VOLE_BIN" >&2; exit 1; }
  mkdir -p "$MACOS_DIR" "$RULES_DST"
  rm -f "$MACOS_DIR/vole"
  cp -f "$VOLE_BIN" "$MACOS_DIR/$SIDECAR_NAME"
  chmod 755 "$MACOS_DIR/$SIDECAR_NAME"
fi
```

注意：把后面原有的 `mkdir -p` / `cp` / collision 检查与 rules rsync **接到**上述分支之后，避免重复 `mkdir` 或漏掉 `RULES_DST`。Universal 分支也必须 `mkdir -p "$MACOS_DIR" "$RULES_DST"` 并保留 PRODUCT_NAME inode 碰撞检查与 rules `rsync`。

- [ ] **Step 4: 语法与最小验证**

```bash
bash -n scripts/lib-universal.sh
bash -n scripts/embed-vole.sh
# 若本机有 VOLE_SRC 且可编：
CONFIGURATION=Release VOLE_UNIVERSAL=1 \
  SRCROOT="$PWD" TARGET_BUILD_DIR=/tmp/vole-uni-test \
  CONTENTS_FOLDER_PATH=Vole.app/Contents \
  PRODUCT_NAME=Vole \
  bash scripts/embed-vole.sh
lipo -archs /tmp/vole-uni-test/Vole.app/Contents/MacOS/vole-cli
# Expected: 含 arm64 与 x86_64（顺序不限）
```

- [ ] **Step 5: Commit**

```bash
git add scripts/lib-universal.sh scripts/embed-vole.sh
git commit -m "$(cat <<'EOF'
feat: build universal vole-cli sidecar on Release

Lipo aarch64 + x86_64 cargo targets so the embedded sidecar matches
Apple Silicon and Intel Macs in release DMGs.
EOF
)"
```

---

### Task 2: Archive 强制双架构 + export 后门禁

**Files:**
- Modify: `scripts/archive-and-export.sh`
- Test: `bash -n`；有签名环境时跑 archive（或至少确认 xcodebuild 参数行）

**Interfaces:**
- Consumes: `require_app_universal` from `scripts/lib-universal.sh`
- Produces: `dist/Vole.app` 内三个 MacOS 可执行文件均为 Universal；否则 archive-and-export 非 0

- [ ] **Step 1: 确认当前门禁会失败（若已有非 Universal dist）**

```bash
# shellcheck source=scripts/lib-universal.sh
source scripts/lib-universal.sh
require_app_universal dist/Vole.app
# Expected before Task 2 complete / old build: FAIL on missing arch
```

- [ ] **Step 2: 改 `archive-and-export.sh`**

在 `source .../lib-signing-env.sh` 之后增加：

```bash
# shellcheck source=lib-universal.sh
source "$ROOT/scripts/lib-universal.sh"
```

在 `xcodebuild ... archive` 调用中增加（Release 路径始终双架构；与 `CONFIGURATION=Release` 默认一致）：

```bash
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -archivePath "$ARCHIVE_PATH" \
  -derivedDataPath "$DERIVED_DATA" \
  -destination "generic/platform=macOS" \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="$IDENTITY" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  OTHER_CODE_SIGN_FLAGS="--timestamp" \
  archive
```

在 `ensure_nested_hardened_runtime` / `require_app_hardened_runtime` **之后**、最终 `codesign --verify` 附近增加：

```bash
echo "==> require universal (arm64 + x86_64)"
require_app_universal "$APP"
```

- [ ] **Step 3: 语法检查**

```bash
bash -n scripts/archive-and-export.sh
```

Expected: 无输出、exit 0

- [ ] **Step 4: Commit**

```bash
git add scripts/archive-and-export.sh
git commit -m "$(cat <<'EOF'
feat: archive macOS app as universal and gate arches

Force arm64+x86_64 on xcodebuild archive and fail export if any
MacOS executable is thin.
EOF
)"
```

---

### Task 3: CI Release 安装双 Rust target

**Files:**
- Modify: `.github/workflows/release.yml`

**Interfaces:**
- Consumes: Task 1 embed Universal cargo builds
- Produces: CI runner 具备 `aarch64-apple-darwin` 与 `x86_64-apple-darwin` targets

- [ ] **Step 1: 改 Rust toolchain step**

将：

```yaml
      - name: Install Rust toolchain
        uses: dtolnay/rust-toolchain@stable
        with:
          toolchain: "1.97.1"
```

改为：

```yaml
      - name: Install Rust toolchain
        uses: dtolnay/rust-toolchain@stable
        with:
          toolchain: "1.97.1"
          targets: aarch64-apple-darwin, x86_64-apple-darwin
```

- [ ] **Step 2: 目视确认后续仍调用 `archive-and-export.sh` → `notarize-app.sh` → `package-dmg.sh`（无需改顺序）**

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/release.yml
git commit -m "$(cat <<'EOF'
ci: install both apple-darwin targets for universal release

Release embed builds vole-cli for arm64 and x86_64 before lipo.
EOF
)"
```

---

### Task 4: 文档对齐（设计非目标翻转 + README）

**Files:**
- Modify: `docs/wukong-code/specs/2026-08-10-2315-macos-dmg-ci-release-design.md`
- Modify: `README.md`
- Modify: `README.zh-CN.md`

- [ ] **Step 1: 更新设计文档**

在 §8 非目标中**删除**这一行：

```markdown
- Universal binary 双架构强制（跟随当前 archive 架构）
```

在合适位置（建议新建 §3.1 或并入 §3 / §5）写明目标：

```markdown
## Universal binary

Release / CI 产出的 `Vole.app`（及 DMG/zip）内以下 Mach-O 必须同时包含 `arm64` 与 `x86_64`：

- `Contents/MacOS/Vole`
- `Contents/MacOS/vole-cli`
- `Contents/MacOS/VolePrivilegedHelper`

实现：`archive-and-export.sh` 设 `ARCHS=arm64 x86_64` + `ONLY_ACTIVE_ARCH=NO`；`embed-vole.sh` 在 Release（或 `VOLE_UNIVERSAL=1`）双 target cargo + `lipo`；export 后 `require_app_universal` 门禁。Debug 本机构建不强制 Universal。
```

验收表增加一行：

```markdown
| Universal | `lipo -archs` 对上述三个可执行文件均含 arm64 与 x86_64 |
```

- [ ] **Step 2: README 安装说明**

`README.md` Download & install 在 version 行附近增加一句：

```markdown
The DMG is a **Universal** build (Apple Silicon and Intel).
```

`README.zh-CN.md` 对应：

```markdown
安装包为 **Universal**（同时支持 Apple Silicon 与 Intel）。
```

- [ ] **Step 3: Commit**

```bash
git add \
  docs/wukong-code/specs/2026-08-10-2315-macos-dmg-ci-release-design.md \
  README.md \
  README.zh-CN.md
git commit -m "$(cat <<'EOF'
docs: require universal binaries in macOS DMG releases

Flip the prior non-goal and note Apple Silicon + Intel support in READMEs.
EOF
)"
```

---

## Self-Review

1. **Spec coverage:** 双架构 sidecar ✅ Task 1；App+Helper archive ✅ Task 2；门禁 ✅ Task 2；CI targets ✅ Task 3；文档 ✅ Task 4；单 DMG / Debug 不强制 ✅ Global Constraints
2. **Placeholders:** 无 TBD；步骤含完整代码与命令
3. **Type consistency:** 可执行文件名 `Vole` / `vole-cli` / `VolePrivilegedHelper` 与现有 bundle 一致；`require_app_universal` 签名在 Task 1 定义、Task 2 消费
