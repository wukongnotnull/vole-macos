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
# Not named `vole`: PRODUCT_NAME=Vole would collide on case-insensitive APFS.
SIDECAR_NAME="vole-cli"

PRODUCT_NAME="${PRODUCT_NAME:-}"
if [[ -n "$PRODUCT_NAME" && "$(printf '%s' "$PRODUCT_NAME" | tr '[:upper:]' '[:lower:]')" == "$(printf '%s' "$SIDECAR_NAME" | tr '[:upper:]' '[:lower:]')" ]]; then
  echo "error: PRODUCT_NAME='$PRODUCT_NAME' collides with embedded sidecar '$SIDECAR_NAME'" >&2
  exit 1
fi

if [[ ! -d "$VOLE_SRC/crates/vole-cli" ]]; then
  echo "error: vole source not found at: $VOLE_SRC" >&2
  echo "hint: clone vole next to vole-macos, or set VOLE_SRC" >&2
  exit 1
fi

CONFIGURATION="${CONFIGURATION:-Debug}"
want_universal=0
if [[ "$CONFIGURATION" == "Release" || "${VOLE_UNIVERSAL:-0}" == "1" ]]; then
  want_universal=1
fi

echo "note: building vole-cli --release from $VOLE_SRC (cargo=$CARGO, universal=$want_universal)"
(
  cd "$VOLE_SRC"
  if [[ "$want_universal" -eq 1 ]]; then
    if command -v rustup >/dev/null 2>&1; then
      rustup target add aarch64-apple-darwin x86_64-apple-darwin >/dev/null 2>&1 || true
    fi
    "$CARGO" build -p vole-cli --release --target aarch64-apple-darwin
    "$CARGO" build -p vole-cli --release --target x86_64-apple-darwin
  else
    "$CARGO" build -p vole-cli --release
  fi
)

mkdir -p "$MACOS_DIR" "$RULES_DST"
# Drop legacy name that collided with PRODUCT_NAME=Vole.
rm -f "$MACOS_DIR/vole" "$MACOS_DIR/$SIDECAR_NAME"

if [[ "$want_universal" -eq 1 ]]; then
  ARM_BIN="$VOLE_SRC/target/aarch64-apple-darwin/release/vole"
  X86_BIN="$VOLE_SRC/target/x86_64-apple-darwin/release/vole"
  if [[ ! -x "$ARM_BIN" || ! -x "$X86_BIN" ]]; then
    echo "error: missing per-arch vole binaries for lipo" >&2
    echo "  expected: $ARM_BIN" >&2
    echo "  expected: $X86_BIN" >&2
    exit 1
  fi
  lipo -create -output "$MACOS_DIR/$SIDECAR_NAME" "$ARM_BIN" "$X86_BIN"
  chmod 755 "$MACOS_DIR/$SIDECAR_NAME"
  archs="$(lipo -archs "$MACOS_DIR/$SIDECAR_NAME")"
  echo "note: lipo vole-cli arches: $archs"
  echo "$archs" | tr ' ' '\n' | grep -qx arm64
  echo "$archs" | tr ' ' '\n' | grep -qx x86_64
else
  VOLE_BIN="$VOLE_SRC/target/release/vole"
  if [[ ! -x "$VOLE_BIN" ]]; then
    echo "error: expected executable at $VOLE_BIN" >&2
    exit 1
  fi
  cp -f "$VOLE_BIN" "$MACOS_DIR/$SIDECAR_NAME"
  chmod 755 "$MACOS_DIR/$SIDECAR_NAME"
fi

if [[ -n "$PRODUCT_NAME" && -e "$MACOS_DIR/$PRODUCT_NAME" ]]; then
  sidecar_ino="$(stat -f '%i' "$MACOS_DIR/$SIDECAR_NAME")"
  app_ino="$(stat -f '%i' "$MACOS_DIR/$PRODUCT_NAME")"
  if [[ "$sidecar_ino" == "$app_ino" ]]; then
    echo "error: $MACOS_DIR/$SIDECAR_NAME and $MACOS_DIR/$PRODUCT_NAME are the same inode" >&2
    exit 1
  fi
fi

shopt -s nullglob
RULES=( "$VOLE_SRC/data/rules/"*.toml )
if (( ${#RULES[@]} == 0 )); then
  echo "error: no rules toml under $VOLE_SRC/data/rules" >&2
  exit 1
fi
rsync -a --delete "$VOLE_SRC/data/rules/" "$RULES_DST/"

echo "note: embedded vole → $MACOS_DIR/$SIDECAR_NAME"
echo "note: embedded rules → $RULES_DST ($(ls -1 "$RULES_DST" | wc -l | tr -d ' ') files)"
