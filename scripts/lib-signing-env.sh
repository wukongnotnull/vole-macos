# Shared env loader for vole-macos signing scripts.
# shellcheck shell=bash
# Sourced by check-signing / archive / notarize — not meant to be executed alone.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VOLE_SIBLING="${VOLE_SRC:-$ROOT/../vole}"

# Prefer local signing.env, then sibling vole's (shared profile name).
# shellcheck source=/dev/null
if [[ -f "$ROOT/scripts/signing.env" ]]; then
  source "$ROOT/scripts/signing.env"
elif [[ -f "$VOLE_SIBLING/scripts/signing.env" ]]; then
  source "$VOLE_SIBLING/scripts/signing.env"
fi

IDENTITY="${VOLE_CODESIGN_IDENTITY:-Developer ID Application: Kong Wu (WCYC8XY4V2)}"
PROFILE="${VOLE_NOTARY_PROFILE:-vole-notary}"
TEAM_ID="${APPLE_TEAM_ID:-WCYC8XY4V2}"

warn_sandbox_home() {
  local real_home="${VOLE_KEYCHAIN_HOME:-}"
  if [[ -z "$real_home" ]]; then
    real_home="$(dscl . -read "/Users/$(whoami)" NFSHomeDirectory 2>/dev/null | awk '{print $2}')"
  fi
  real_home="${real_home:-$HOME}"
  if [[ "$HOME" != "$real_home" && "$HOME" == /var/folders/* ]]; then
    echo "WARN: Cursor/CI 沙箱 HOME ($HOME) ≠ 用户目录 ($real_home)" >&2
    echo "      钥匙串访问 GUI 里可见，但 IDE 内置终端可能读不到私钥 / notary profile。" >&2
    echo "      请在「终端.app」或 iTerm 中运行本脚本。" >&2
  fi
  REAL_HOME="$real_home"
  LOGIN_KEYCHAIN="${VOLE_LOGIN_KEYCHAIN:-$REAL_HOME/Library/Keychains/login.keychain-db}"
}

notary_profile_ok() {
  local profile="$1"
  # Do not pass --limit: older notarytool builds reject it and false-negative
  # a valid keychain profile as "missing credentials".
  if xcrun notarytool history --keychain-profile "$profile" >/dev/null 2>&1; then
    return 0
  fi
  # API-key profiles may not respond to history; keychain entry is enough.
  if security find-generic-password -a "$profile" 2>/dev/null | grep -q 'class: "genp"'; then
    return 0
  fi
  return 1
}


# Nested Mach-Os must have Hardened Runtime for notarization (Apple common issue #3087724).
# Xcode exportArchive signs Contents/MacOS/vole-cli (copied sidecar) without --options runtime.
macho_has_hardened_runtime() {
  local bin="$1"
  local out
  # Capture first: with pipefail, `grep -q` closing the pipe early makes codesign SIGPIPE (141).
  out="$(codesign -dv --verbose=4 "$bin" 2>&1 || true)"
  printf '%s
' "$out" | grep -Eq 'flags=0x[0-9a-f]+\([^)]*runtime'
}

list_app_machos() {
  local app="$1"
  local macos="$app/Contents/MacOS"
  [[ -d "$macos" ]] || return 0
  find "$macos" -type f -perm +111 2>/dev/null || true
}

# Re-sign vole-cli with hardened runtime, then re-seal the outer .app (preserve entitlements).
ensure_nested_hardened_runtime() {
  local app="$1"
  local sidecar="$app/Contents/MacOS/vole-cli"
  local ent
  local bin

  [[ -d "$app" ]] || { echo "ensure_nested_hardened_runtime: missing app: $app" >&2; return 2; }
  [[ -x "$sidecar" ]] || { echo "ensure_nested_hardened_runtime: missing sidecar: $sidecar" >&2; return 2; }

  local resigned=0
  if ! macho_has_hardened_runtime "$sidecar"; then
    echo "==> codesign sidecar with hardened runtime: $sidecar"
    codesign --force --options runtime --timestamp --sign "$IDENTITY" "$sidecar"
    resigned=1
  else
    echo "OK: sidecar already has hardened runtime"
  fi

  if [[ "$resigned" -eq 0 ]] && codesign --verify --deep --strict "$app" >/dev/null 2>&1; then
    return 0
  fi

  # Outer app seal must be refreshed after nested re-sign.
  # Export as XML (`:-`); raw blob path form is not accepted by codesign --entitlements on re-sign.
  ent="$(mktemp -t vole-macos-ent.XXXXXX).plist"
  if ! codesign -d --entitlements :- "$app" >"$ent" 2>/dev/null; then
    rm -f "$ent"
    echo "ensure_nested_hardened_runtime: failed to read entitlements from $app" >&2
    return 1
  fi
  if [[ ! -s "$ent" ]]; then
    # No entitlements blob — still re-seal without --entitlements.
    rm -f "$ent"
    ent=""
  fi
  echo "==> re-seal app with hardened runtime: $app"
  if [[ -n "$ent" ]]; then
    codesign --force --options runtime --timestamp --entitlements "$ent" --sign "$IDENTITY" "$app"
    rm -f "$ent"
  else
    codesign --force --options runtime --timestamp --sign "$IDENTITY" "$app"
  fi

  codesign --verify --deep --strict --verbose=2 "$app"
}

require_app_hardened_runtime() {
  local app="$1"
  local bin
  local failed=0

  [[ -d "$app" ]] || { echo "require_app_hardened_runtime: missing $app" >&2; return 2; }

  while IFS= read -r bin; do
    [[ -n "$bin" ]] || continue
    if macho_has_hardened_runtime "$bin"; then
      echo "OK: hardened runtime — $bin"
    else
      echo "FAIL: missing hardened runtime — $bin" >&2
      failed=1
    fi
  done < <(list_app_machos "$app")

  if [[ "$failed" -ne 0 ]]; then
    echo "公证前须对嵌套可执行文件启用 Hardened Runtime（codesign --options runtime）。" >&2
    echo "  重新导出: bash scripts/archive-and-export.sh" >&2
    return 1
  fi
  return 0
}
