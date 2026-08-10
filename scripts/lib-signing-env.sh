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
