#!/usr/bin/env bash
# Zip Vole.app → notarytool submit (vole-notary) → stapler staple → spctl verify.
# Without a keychain profile / API key: exits non-zero and never submits.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib-signing-env.sh
source "$ROOT/scripts/lib-signing-env.sh"

warn_sandbox_home

APP="${VOLE_APP:-$ROOT/dist/Vole.app}"

usage() {
  cat <<EOF
Usage: bash scripts/notarize-app.sh [--check-only] [path/to/Vole.app]

Notarizes and staples a Developer ID exported .app using keychain profile
'$PROFILE' (shared with sibling vole).

Options:
  --check-only   Verify .app + notary credentials only; do not submit

Env:
  VOLE_APP              Default: dist/Vole.app
  VOLE_NOTARY_PROFILE   Default: vole-notary
  APPLE_API_KEY_*       Alternative to keychain profile (CI)

One-time credentials (Terminal.app, sibling vole):
  cd ../vole && bash scripts/setup-notary-profile.sh
EOF
}

CHECK_ONLY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check-only) CHECK_ONLY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      APP="$1"
      shift
      ;;
  esac
done

echo "==> notarize-app"
echo "    app: $APP"
echo "    profile: $PROFILE"

if [[ ! -d "$APP" ]]; then
  echo "notarize-app: .app not found at $APP" >&2
  echo "  Build first: bash scripts/archive-and-export.sh" >&2
  exit 2
fi

CAN_NOTARY=0
if notary_profile_ok "$PROFILE"; then
  CAN_NOTARY=1
elif [[ -n "${APPLE_API_KEY_ID:-}" && -n "${APPLE_API_ISSUER_ID:-}" ]]; then
  CAN_NOTARY=1
fi

if [[ "$CAN_NOTARY" -eq 0 ]]; then
  echo "notarize-app: no notary credentials — refusing to submit." >&2
  echo "  Expected keychain profile: $PROFILE" >&2
  echo "  One-time (Terminal.app):" >&2
  echo "    cd \"${VOLE_SIBLING}\" && bash scripts/setup-notary-profile.sh" >&2
  echo "  Or set APPLE_API_KEY_ID + APPLE_API_ISSUER_ID (+ KEY path/base64)." >&2
  echo "  See: ../vole/docs/findings/2026-07-phase5-signing.md" >&2
  exit 3
fi

if [[ "$CHECK_ONLY" -eq 1 ]]; then
  echo "OK: --check-only (app present + notary credentials usable)"
  exit 0
fi

run_notary_submit() {
  local zip="$1"
  if notary_profile_ok "$PROFILE"; then
    xcrun notarytool submit "$zip" --keychain-profile "$PROFILE" --wait
    return 0
  fi
  if [[ -n "${APPLE_API_KEY_ID:-}" && -n "${APPLE_API_ISSUER_ID:-}" ]]; then
    local key_file="${APPLE_API_KEY_PATH:-${RUNNER_TEMP:-/tmp}/vole-macos-AuthKey.p8}"
    if [[ -n "${APPLE_API_KEY_BASE64:-}" ]]; then
      echo "$APPLE_API_KEY_BASE64" | base64 --decode > "$key_file"
    elif [[ ! -f "$key_file" ]]; then
      echo "notarize-app: APPLE_API_KEY_BASE64 or APPLE_API_KEY_PATH required" >&2
      return 1
    fi
    xcrun notarytool submit "$zip" \
      --key "$key_file" \
      --key-id "$APPLE_API_KEY_ID" \
      --issuer "$APPLE_API_ISSUER_ID" \
      --wait
    return 0
  fi
  return 1
}

ZIP="$(mktemp -t vole-macos-notarize).zip"
cleanup() { rm -f "$ZIP"; }
trap cleanup EXIT

echo "==> zip for notarytool"
ditto -c -k --keepParent "$APP" "$ZIP"

echo "==> notarytool submit --wait"
run_notary_submit "$ZIP"

echo "==> stapler staple"
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"

echo "==> spctl assess"
spctl -a -vv --type execute "$APP"

echo "OK: notarized and stapled $APP"
