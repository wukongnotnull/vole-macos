#!/usr/bin/env bash
# Shared Universal (fat) Mach-O checks for vole-macos release.
# shellcheck shell=bash

macho_has_arches() {
  local bin="$1"
  shift
  local archs needed
  [[ -f "$bin" ]] || return 1
  archs="$(lipo -archs "$bin" 2>/dev/null || true)"
  [[ -n "$archs" ]] || return 1
  for needed in "$@"; do
    # word match: lipo prints e.g. "x86_64 arm64"
    echo "$archs" | tr ' ' '\n' | grep -qx "$needed" || return 1
  done
  return 0
}

require_macho_arches() {
  local bin="$1"
  shift
  local archs
  if macho_has_arches "$bin" "$@"; then
    archs="$(lipo -archs "$bin")"
    echo "OK: universal arches ($archs) — $bin"
    return 0
  fi
  archs="$(lipo -archs "$bin" 2>/dev/null || echo "<unreadable>")"
  echo "FAIL: expected arches [$*], got [$archs] — $bin" >&2
  return 1
}

require_app_universal() {
  local app="$1"
  local macos="$app/Contents/MacOS"
  local failed=0
  local name

  [[ -d "$macos" ]] || {
    echo "require_app_universal: missing $macos" >&2
    return 2
  }

  for name in Vole vole-cli VolePrivilegedHelper; do
    if [[ ! -f "$macos/$name" ]]; then
      echo "FAIL: missing executable — $macos/$name" >&2
      failed=1
      continue
    fi
    require_macho_arches "$macos/$name" arm64 x86_64 || failed=1
  done

  if [[ "$failed" -ne 0 ]]; then
    echo "Release app must be Universal (arm64 + x86_64) for all MacOS executables." >&2
    return 1
  fi
  return 0
}
