#!/bin/zsh
# Builds a throwaway HOME for the opt-in VoleE2EUITests (they really apply plans).
#
#   H=$(./scripts/make-ui-fixtures.sh)          # defaults to $TMPDIR/vole-ui-home
#   TEST_RUNNER_VOLE_UI_HOME=$H \
#     xcodebuild -scheme vole-macos test -only-testing:vole-macosUITests/VoleE2EUITests
#
# The target folder is wiped first, so it must be new or a previous fixture HOME.
# Not under /tmp or /var/tmp: those are on the root helper's whitelist, so the app
# would route fixture rows to the helper instead of the trash.
[ -n "${ZSH_VERSION:-}" ] || exec zsh "$0" "$@"
set -euo pipefail

TMP=${TMPDIR:-$HOME/Library/Caches}
H=${1:-${TMP%/}/vole-ui-home}
H=${H%/}
MARKER=.vole-ui-fixture

case "$H" in
  /*) ;;
  *) echo "FAIL: pass an absolute path" >&2; exit 1 ;;
esac
if [[ "${H:A}" == "${HOME:A}" || "${H:A}" == "/" ]]; then
  echo "FAIL: refusing to use $H as fixture HOME" >&2; exit 1
fi
case "${H:A}" in
  /private/tmp|/private/tmp/*|/private/var/tmp|/private/var/tmp/*)
    echo "FAIL: $H is under /tmp or /var/tmp (root helper whitelist); use \$TMPDIR" >&2; exit 1 ;;
esac
if [[ -e "$H" && ! -e "$H/$MARKER" ]]; then
  echo "FAIL: $H exists and is not a fixture HOME (no $MARKER); pick a new folder" >&2; exit 1
fi

rm -rf "$H"; mkdir -p "$H"; touch "$H/$MARKER"

exec 3>&1 1>&2  # progress to stderr, fixture path alone to stdout

# Purge: stale node_modules / target
mkdir -p "$H/Projects/uijs/node_modules/pad" "$H/Projects/uirs/target/debug"
echo '{}' > "$H/Projects/uijs/package.json"; head -c 200000 /dev/urandom > "$H/Projects/uijs/node_modules/pad/i.js"
printf '[package]\nname="x"\n' > "$H/Projects/uirs/Cargo.toml"; head -c 300000 /dev/urandom > "$H/Projects/uirs/target/debug/bin"
for p in "$H/Projects/uijs/node_modules" "$H/Projects/uijs/node_modules/pad" "$H/Projects/uijs/node_modules/pad/i.js" \
         "$H/Projects/uirs/target" "$H/Projects/uirs/target/debug" "$H/Projects/uirs/target/debug/bin"; do
  touch -t 202601010000 "$p"
done

# Installer
mkdir -p "$H/Downloads"; head -c 100000 /dev/urandom > "$H/Downloads/VoleUITestApp.dmg"

# Worktree
mkdir -p "$H/Projects/uirepo"
(
  cd "$H/Projects/uirepo"
  git init -q && echo a > a && git add a
  git -c user.name=t -c user.email=t@t commit -qm init
  git worktree add -q "$H/Projects/uirepo-wt" -b uiwt
)

# Agent
mkdir -p "$H/.cursor/Cache"; head -c 200000 /dev/urandom > "$H/.cursor/Cache/data"

# Uninstall: app bundle plus user-domain leftovers
A="$H/Applications/VoleUIFixture.app/Contents"; mkdir -p "$A/MacOS"
cat > "$A/Info.plist" <<P
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>CFBundleIdentifier</key><string>com.example.voleuifixture</string><key>CFBundleName</key><string>VoleUIFixture</string><key>CFBundleExecutable</key><string>VoleUIFixture</string></dict></plist>
P
echo x > "$A/MacOS/VoleUIFixture"
mkdir -p "$H/Library/Application Support/com.example.voleuifixture" "$H/Library/Preferences"
echo x > "$H/Library/Application Support/com.example.voleuifixture/db"
echo x > "$H/Library/Preferences/com.example.voleuifixture.plist"

# Analyze
mkdir -p "$H/AnalyzeMe/big"; head -c 3000000 /dev/urandom > "$H/AnalyzeMe/big/huge.bin"

echo "OK: fixture HOME at $H"
echo "$H" >&3
