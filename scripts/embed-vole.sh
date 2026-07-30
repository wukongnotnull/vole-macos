#!/usr/bin/env bash
set -euo pipefail

SRCROOT="${SRCROOT:?SRCROOT required}"
TARGET_BUILD_DIR="${TARGET_BUILD_DIR:?TARGET_BUILD_DIR required}"
CONTENTS_FOLDER_PATH="${CONTENTS_FOLDER_PATH:?CONTENTS_FOLDER_PATH required}"

VOLE_SRC="${VOLE_SRC:-$SRCROOT/../vole}"
CONTENTS="$TARGET_BUILD_DIR/$CONTENTS_FOLDER_PATH"
MACOS_DIR="$CONTENTS/MacOS"
RULES_DST="$CONTENTS/share/vole/rules"

if [[ ! -d "$VOLE_SRC/crates/vole-cli" ]]; then
  echo "error: vole source not found at: $VOLE_SRC" >&2
  echo "hint: clone vole next to vole-macos, or set VOLE_SRC" >&2
  exit 1
fi

if ! command -v cargo >/dev/null 2>&1; then
  echo "error: cargo not found in PATH" >&2
  exit 1
fi

echo "note: building vole-cli --release from $VOLE_SRC"
(
  cd "$VOLE_SRC"
  cargo build -p vole-cli --release
)

VOLE_BIN="$VOLE_SRC/target/release/vole"
if [[ ! -x "$VOLE_BIN" ]]; then
  echo "error: expected executable at $VOLE_BIN" >&2
  exit 1
fi

mkdir -p "$MACOS_DIR" "$RULES_DST"
cp -f "$VOLE_BIN" "$MACOS_DIR/vole"
chmod 755 "$MACOS_DIR/vole"

shopt -s nullglob
RULES=( "$VOLE_SRC/data/rules/"*.toml )
if (( ${#RULES[@]} == 0 )); then
  echo "error: no rules toml under $VOLE_SRC/data/rules" >&2
  exit 1
fi
rsync -a --delete "$VOLE_SRC/data/rules/" "$RULES_DST/"

echo "note: embedded vole → $MACOS_DIR/vole"
echo "note: embedded rules → $RULES_DST ($(ls -1 "$RULES_DST" | wc -l | tr -d ' ') files)"
