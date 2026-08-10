#!/usr/bin/env bash
# xcodebuild archive + exportArchive (Developer ID) → dist/Vole.app
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib-signing-env.sh
source "$ROOT/scripts/lib-signing-env.sh"

warn_sandbox_home

SCHEME="${VOLE_MACOS_SCHEME:-vole-macos}"
CONFIGURATION="${VOLE_MACOS_CONFIGURATION:-Release}"
ARCHIVE_PATH="${VOLE_ARCHIVE_PATH:-$ROOT/build/Vole.xcarchive}"
EXPORT_PATH="${VOLE_EXPORT_PATH:-$ROOT/dist}"
EXPORT_OPTIONS="${VOLE_EXPORT_OPTIONS:-$ROOT/scripts/ExportOptions.plist}"
DERIVED_DATA="${VOLE_DERIVED_DATA:-$ROOT/build/DerivedData}"

usage() {
  cat <<EOF
Usage: bash scripts/archive-and-export.sh [--check-only]

Archives scheme $SCHEME and exports a Developer ID signed Vole.app to:
  $EXPORT_PATH/Vole.app

Options:
  --check-only   Verify Xcode project / ExportOptions / identity; no archive

Env:
  VOLE_SRC                  Sibling vole source (for embed build phase)
  VOLE_CODESIGN_IDENTITY    Developer ID Application identity
                            (default: Developer ID Application: Kong Wu (WCYC8XY4V2))
  VOLE_ARCHIVE_PATH         Default: build/Vole.xcarchive
  VOLE_EXPORT_PATH          Default: dist
  VOLE_MACOS_SCHEME         Default: vole-macos
  VOLE_MACOS_CONFIGURATION  Default: Release
EOF
}

identity_available() {
  if security find-identity -v -p codesigning 2>/dev/null | grep -qF "$IDENTITY"; then
    return 0
  fi
  if [[ -f "${LOGIN_KEYCHAIN:-}" ]] \
    && security find-identity -v -p codesigning "$LOGIN_KEYCHAIN" 2>/dev/null \
      | grep -qF "$IDENTITY"; then
    return 0
  fi
  return 1
}

require_identity() {
  if identity_available; then
    return 0
  fi
  echo "FAIL: signing identity not found: $IDENTITY" >&2
  echo "      Archive/export requires Developer ID Application (not Mac Development)." >&2
  echo "      Import the cert into the keychain, or set VOLE_CODESIGN_IDENTITY." >&2
  echo "      Run: bash scripts/check-signing.sh  (use Terminal.app)" >&2
  exit 1
}

CHECK_ONLY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check-only) CHECK_ONLY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

PROJECT="$ROOT/vole-macos.xcodeproj"
[[ -d "$PROJECT" ]] || { echo "archive-and-export: missing $PROJECT" >&2; exit 2; }
[[ -f "$EXPORT_OPTIONS" ]] || { echo "archive-and-export: missing $EXPORT_OPTIONS" >&2; exit 2; }

echo "==> archive-and-export"
echo "    project: $PROJECT"
echo "    scheme: $SCHEME ($CONFIGURATION)"
echo "    identity: $IDENTITY"
echo "    export options: $EXPORT_OPTIONS"

require_identity

if [[ "$CHECK_ONLY" -eq 1 ]]; then
  echo "OK: --check-only passed (project + ExportOptions + identity)"
  exit 0
fi

mkdir -p "$(dirname "$ARCHIVE_PATH")" "$EXPORT_PATH" "$DERIVED_DATA"
rm -rf "$ARCHIVE_PATH"

# Force Developer ID for all targets in the scheme (app + VolePrivilegedHelper).
# Project defaults are CODE_SIGN_STYLE=Automatic → "Mac Development", which CI
# does not import and which is wrong for the notarize/distribution path.
echo "==> xcodebuild archive (Developer ID, manual)"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -archivePath "$ARCHIVE_PATH" \
  -derivedDataPath "$DERIVED_DATA" \
  -destination "generic/platform=macOS" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="$IDENTITY" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  OTHER_CODE_SIGN_FLAGS="--timestamp" \
  archive

echo "==> xcodebuild -exportArchive"
rm -rf "$EXPORT_PATH/Vole.app"
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS"

APP="$EXPORT_PATH/Vole.app"
if [[ ! -d "$APP" ]]; then
  echo "archive-and-export: expected $APP after export" >&2
  ls -la "$EXPORT_PATH" >&2 || true
  exit 2
fi

echo "==> ensure nested hardened runtime (vole-cli sidecar)"
ensure_nested_hardened_runtime "$APP"
require_app_hardened_runtime "$APP"

echo "==> codesign verify"
codesign --verify --deep --strict --verbose=2 "$APP"
echo "OK: exported $APP"
echo "Next: bash scripts/notarize-app.sh"
