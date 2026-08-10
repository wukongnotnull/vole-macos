#!/usr/bin/env bash
# Package a notarized+stapled Vole.app into dist/Vole-<version>.dmg (UDZO).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="${VOLE_APP:-$ROOT/dist/Vole.app}"
OUT_DIR="${OUT_DIR:-$ROOT/dist}"
VOL_NAME="${VOLE_DMG_VOLNAME:-Vole}"
ALLOW_UNSTAPLED="${VOLE_DMG_ALLOW_UNSTAPLED:-0}"

usage() {
  cat <<EOF
Usage: bash scripts/package-dmg.sh [path/to/Vole.app]

Creates a drag-to-Applications DMG from a notarized+stapled .app:
  $OUT_DIR/Vole-<version>.dmg

Env:
  VOLE_APP                    Default: dist/Vole.app
  OUT_DIR                     Default: dist
  VOLE_DMG_VERSION            Override version (else Info.plist / pbxproj)
  VOLE_DMG_VOLNAME            Volume name (default: Vole)
  VOLE_DMG_ALLOW_UNSTAPLED=1  WARN and continue if stapler validate fails

Prereq:
  bash scripts/notarize-app.sh
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    *)
      APP="$1"
      shift
      ;;
  esac
done

echo "==> package-dmg"
echo "    app: $APP"

if [[ ! -d "$APP" ]]; then
  echo "package-dmg: .app not found at $APP" >&2
  echo "  Build + notarize first:" >&2
  echo "    bash scripts/archive-and-export.sh" >&2
  echo "    bash scripts/notarize-app.sh" >&2
  exit 2
fi

read_version() {
  if [[ -n "${VOLE_DMG_VERSION:-}" ]]; then
    printf '%s' "$VOLE_DMG_VERSION"
    return 0
  fi
  local plist="$APP/Contents/Info.plist"
  if [[ -f "$plist" ]]; then
    local v
    v="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$plist" 2>/dev/null || true)"
    if [[ -n "$v" ]]; then
      printf '%s' "$v"
      return 0
    fi
  fi
  local pbx="$ROOT/vole-macos.xcodeproj/project.pbxproj"
  if [[ -f "$pbx" ]]; then
    local mv
    mv="$(grep -m1 'MARKETING_VERSION = ' "$pbx" | sed 's/.*= \(.*\);/\1/' | tr -d '[:space:]')"
    if [[ -n "$mv" ]]; then
      printf '%s' "$mv"
      return 0
    fi
  fi
  echo "package-dmg: could not determine version (set VOLE_DMG_VERSION)" >&2
  exit 2
}

VERSION="$(read_version)"
DMG="$OUT_DIR/Vole-${VERSION}.dmg"
echo "    version: $VERSION"
echo "    dmg: $DMG"

echo "==> stapler validate"
if xcrun stapler validate "$APP"; then
  echo "OK: staple present"
else
  if [[ "$ALLOW_UNSTAPLED" == "1" ]]; then
    echo "WARN: stapler validate failed — continuing (VOLE_DMG_ALLOW_UNSTAPLED=1)" >&2
  else
    echo "package-dmg: app is not stapled (or staple invalid)." >&2
    echo "  Run: bash scripts/notarize-app.sh" >&2
    echo "  Or set VOLE_DMG_ALLOW_UNSTAPLED=1 to package anyway (not for release)." >&2
    exit 3
  fi
fi

STAGE="$(mktemp -d -t vole-macos-dmg)"
cleanup() { rm -rf "$STAGE"; }
trap cleanup EXIT

echo "==> stage drag-to-Applications layout"
ditto "$APP" "$STAGE/Vole.app"
ln -s /Applications "$STAGE/Applications"

mkdir -p "$OUT_DIR"
rm -f "$DMG"

echo "==> hdiutil create (UDZO)"
hdiutil create \
  -volname "$VOL_NAME" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDZO \
  "$DMG"

echo "OK: $DMG"
ls -lh "$DMG"
