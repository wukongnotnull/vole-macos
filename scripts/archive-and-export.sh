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
  VOLE_ARCHIVE_PATH         Default: build/Vole.xcarchive
  VOLE_EXPORT_PATH          Default: dist
  VOLE_MACOS_SCHEME         Default: vole-macos
  VOLE_MACOS_CONFIGURATION  Default: Release
EOF
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
echo "    identity (expected): $IDENTITY"
echo "    export options: $EXPORT_OPTIONS"

# Soft-check identity (export will fail hard if missing).
if ! security find-identity -v -p codesigning 2>/dev/null | grep -qF "$IDENTITY"; then
  if [[ -f "$LOGIN_KEYCHAIN" ]] && security find-identity -v -p codesigning "$LOGIN_KEYCHAIN" 2>/dev/null | grep -qF "$IDENTITY"; then
    :
  else
    echo "WARN: identity not visible to security CLI — export may fail." >&2
    echo "      Run: bash scripts/check-signing.sh  (use Terminal.app)" >&2
  fi
fi

if [[ "$CHECK_ONLY" -eq 1 ]]; then
  echo "OK: --check-only passed (project + ExportOptions present)"
  exit 0
fi

mkdir -p "$(dirname "$ARCHIVE_PATH")" "$EXPORT_PATH" "$DERIVED_DATA"
rm -rf "$ARCHIVE_PATH"

echo "==> xcodebuild archive"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -archivePath "$ARCHIVE_PATH" \
  -derivedDataPath "$DERIVED_DATA" \
  -destination "generic/platform=macOS" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
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

echo "==> codesign verify"
codesign --verify --deep --strict --verbose=2 "$APP"
echo "OK: exported $APP"
echo "Next: bash scripts/notarize-app.sh"
