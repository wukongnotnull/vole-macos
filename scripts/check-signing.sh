#!/usr/bin/env bash
# Verify Developer ID identity + notary profile (vole-notary by default).
# Does not submit to Apple. Safe without credentials (exits clearly).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib-signing-env.sh
source "$ROOT/scripts/lib-signing-env.sh"

warn_sandbox_home

echo "==> check-signing (vole-macos)"
echo "    identity: $IDENTITY"
echo "    notary profile: $PROFILE"
echo "    shell HOME: $HOME"
echo "    keychain home: $REAL_HOME"

find_identities() {
  if [[ -f "$LOGIN_KEYCHAIN" ]]; then
    security find-identity -v -p codesigning "$LOGIN_KEYCHAIN" 2>/dev/null || true
    security find-identity -v -p codesigning 2>/dev/null || true
  else
    security find-identity -v -p codesigning 2>/dev/null || true
  fi
}

FOUND=0
MATCH_LINE=""
while IFS= read -r line; do
  if [[ "$line" == *"$IDENTITY"* ]]; then
    FOUND=1
    MATCH_LINE="$line"
    break
  fi
done < <(find_identities)

if [[ "$FOUND" -eq 0 ]]; then
  echo "FAIL: codesign CLI 未找到 identity。" >&2
  echo >&2
  echo "若「钥匙串访问」里已显示该证书 + 私钥，常见原因：" >&2
  echo "  1. 在 Cursor 内置终端运行（沙箱 HOME）→ 改用终端.app" >&2
  echo "  2. 私钥访问控制未允许 codesign" >&2
  echo "  3. 缺少中间证书 → 从 Apple PKI 安装 Developer ID CA" >&2
  echo >&2
  echo "当前 security find-identity -p codesigning 输出：" >&2
  find_identities | head -10 >&2 || true
  exit 1
fi

echo "OK: codesigning identity found"
echo "    $MATCH_LINE"

if notary_profile_ok "$PROFILE"; then
  echo "OK: notary profile '$PROFILE'"
  exit 0
fi

if [[ -n "${APPLE_API_KEY_ID:-}" && -n "${APPLE_API_ISSUER_ID:-}" && -n "${APPLE_API_KEY_BASE64:-}" ]]; then
  echo "OK: notary API key env (APPLE_API_KEY_ID + ISSUER + BASE64)"
  exit 0
fi

echo "SKIP: notarization not configured (sign / archive OK; notarize-app will refuse)"
echo "      One-time (sibling vole, Terminal.app):"
echo "        cd \"${VOLE_SIBLING}\" && bash scripts/setup-notary-profile.sh"
echo "      Docs: ../vole/docs/findings/2026-07-phase5-signing.md"
exit 0
