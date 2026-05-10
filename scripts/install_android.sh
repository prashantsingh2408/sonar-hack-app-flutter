#!/usr/bin/env bash
# Build release APK and install on a connected Android device (e.g. Vivo via USB).
# Requires: adb, flutter, USB debugging, device showing as "device" in `adb devices`.
#
# Usage (from repo root):
#   ./scripts/install_android.sh
#
# Pick a specific device:
#   ANDROID_SERIAL=10BFCT078Y002PJ ./scripts/install_android.sh
#
# Pass Google web client ID for ID tokens (same as flutter run):
#   GOOGLE_SERVER_CLIENT_ID=xxx.apps.googleusercontent.com ./scripts/install_android.sh

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DEVICE="${ANDROID_SERIAL:-}"
if [[ -z "${DEVICE}" ]]; then
  DEVICE="$(adb devices 2>/dev/null | awk '/\tdevice$/ {print $1; exit}')"
fi
if [[ -z "${DEVICE}" ]]; then
  echo "install_android: no Android device. Connect USB, enable USB debugging, or set ANDROID_SERIAL." >&2
  exit 1
fi

DEFINES=()
if [[ -n "${GOOGLE_SERVER_CLIENT_ID:-}" ]]; then
  DEFINES+=(--dart-define="GOOGLE_SERVER_CLIENT_ID=${GOOGLE_SERVER_CLIENT_ID}")
fi

echo "install_android: building release APK${DEFINES[*]:+ with dart-define}..."
flutter build apk --release "${DEFINES[@]}"

echo "install_android: installing on ${DEVICE}..."
flutter install --release -d "${DEVICE}"

echo "install_android: done (${DEVICE})."
