#!/usr/bin/env bash
# Release APK with same dart-defines as run_with_nextjs_env.sh.

set -euo pipefail

_TOOL_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=load_next_env.sh
source "$_TOOL_DIR/load_next_env.sh"

if [[ -z "${GOOGLE_SERVER_CLIENT_ID:-}" ]]; then
  echo "build_android_apk: AUTH_GOOGLE_ID missing in $NEXT_ROOT/.env.local or .env.vercel.production.local" >&2
  echo "Run: (cd $NEXT_ROOT && npm run env:pull)  or  npm run vercel:env-pull-production" >&2
  exit 1
fi

cd "$FLUTTER_ROOT"
flutter build apk --release \
  --dart-define=GOOGLE_SERVER_CLIENT_ID="$GOOGLE_SERVER_CLIENT_ID" \
  --dart-define=API_ORIGIN="$API_ORIGIN"

APK="$FLUTTER_ROOT/build/app/outputs/flutter-apk/app-release.apk"
echo "APK: $APK"
