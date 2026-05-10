#!/usr/bin/env bash
# Build release APK and install on a USB-connected device (adb).
# Enable Developer options + USB debugging on the phone; accept the RSA prompt.

set -euo pipefail

_TOOL_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=load_next_env.sh
source "$_TOOL_DIR/load_next_env.sh"

if [[ -z "${GOOGLE_SERVER_CLIENT_ID:-}" ]]; then
  echo "connect_install_android: AUTH_GOOGLE_ID missing in $NEXT_ROOT/.env.local or .env.vercel.production.local" >&2
  exit 1
fi

if ! command -v adb >/dev/null 2>&1; then
  echo "connect_install_android: adb not in PATH (install Android platform-tools)." >&2
  exit 1
fi

"$_TOOL_DIR/build_android_apk.sh"

APK="$FLUTTER_ROOT/build/app/outputs/flutter-apk/app-release.apk"
if [[ ! -f "$APK" ]]; then
  echo "connect_install_android: APK not found at $APK" >&2
  exit 1
fi

_FIRST="$(adb devices | awk '$2=="device"{print $1; exit}')"
_COUNT="$(adb devices | awk '$2=="device"{c++} END{print c+0}')"
if [[ -z "${_FIRST:-}" ]] || [[ "${_COUNT:-0}" -eq 0 ]]; then
  echo "connect_install_android: no device in 'adb devices'. Plug in USB, enable USB debugging, authorize this PC." >&2
  exit 1
fi
if [[ "${_COUNT:-0}" -gt 1 ]]; then
  echo "connect_install_android: multiple devices; using first: ${_FIRST}" >&2
fi

adb -s "${_FIRST}" install -r "$APK"
echo "Installed on ${_FIRST}"
