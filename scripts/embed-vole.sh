#!/usr/bin/env bash
set -euo pipefail

SRCROOT="${SRCROOT:?SRCROOT required}"
TARGET_BUILD_DIR="${TARGET_BUILD_DIR:?TARGET_BUILD_DIR required}"
CONTENTS_FOLDER_PATH="${CONTENTS_FOLDER_PATH:?CONTENTS_FOLDER_PATH required}"

# Xcode GUI launches with a minimal PATH (no rustup). Prefer explicit cargo,
# then rustup defaults, then whatever is already on PATH.
if [[ -n "${CARGO:-}" && -x "${CARGO}" ]]; then
  :
elif [[ -x "${HOME}/.cargo/bin/cargo" ]]; then
  CARGO="${HOME}/.cargo/bin/cargo"
elif [[ -x /opt/homebrew/bin/cargo ]]; then
  CARGO=/opt/homebrew/bin/cargo
elif [[ -x /usr/local/bin/cargo ]]; then
  CARGO=/usr/local/bin/cargo
elif command -v cargo >/dev/null 2>&1; then
  CARGO="$(command -v cargo)"
else
  echo "error: cargo not found (Xcode GUI PATH often omits ~/.cargo/bin)" >&2
  echo "hint: install Rust via rustup, or set CARGO=/path/to/cargo in the" >&2
  echo "      'Embed vole sidecar' build phase environment" >&2
  exit 1
fi
# Ensure rustc/rustup siblings resolve when cargo shells out.
export PATH="$(dirname "$CARGO"):${PATH}"

VOLE_SRC="${VOLE_SRC:-$SRCROOT/../vole}"
CONTENTS="$TARGET_BUILD_DIR/$CONTENTS_FOLDER_PATH"
MACOS_DIR="$CONTENTS/MacOS"
RULES_DST="$CONTENTS/share/vole/rules"

if [[ ! -d "$VOLE_SRC/crates/vole-cli" ]]; then
  echo "error: vole source not found at: $VOLE_SRC" >&2
  echo "hint: clone vole next to vole-macos, or set VOLE_SRC" >&2
  exit 1
fi

echo "note: building vole-cli --release from $VOLE_SRC (cargo=$CARGO)"
(
  cd "$VOLE_SRC"
  "$CARGO" build -p vole-cli --release
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
