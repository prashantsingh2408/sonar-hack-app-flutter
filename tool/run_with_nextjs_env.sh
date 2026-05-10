#!/usr/bin/env bash
# Run Flutter with GOOGLE_SERVER_CLIENT_ID from sonar-hack-app env (AUTH_GOOGLE_ID).
# Tries .env.local then .env.vercel.production.local. No prompts.

set -euo pipefail

FLUTTER_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NEXT_ROOT="$(cd "$FLUTTER_ROOT/../sonar-hack-app" && pwd)"

extract_kv() {
  local key="$1"
  local file="$2"
  [[ -f "$file" ]] || return 1
  local line
  line="$(grep -E "^${key}=" "$file" | head -1)" || return 1
  local val="${line#*=}"
  val="${val%$'\r'}"
  val="${val#\"}"
  val="${val%\"}"
  val="${val#\'}"
  val="${val%\'}"
  printf '%s' "$val"
}

ENV_FILE=""
for f in "$NEXT_ROOT/.env.local" "$NEXT_ROOT/.env.vercel.production.local"; do
  [[ -f "$f" ]] || continue
  if v="$(extract_kv AUTH_GOOGLE_ID "$f" 2>/dev/null)" && [[ -n "${v:-}" ]]; then
    ENV_FILE="$f"
    break
  fi
done

GOOGLE_SERVER_CLIENT_ID=""
if [[ -n "${ENV_FILE:-}" ]]; then
  GOOGLE_SERVER_CLIENT_ID="$(extract_kv AUTH_GOOGLE_ID "$ENV_FILE")"
fi

if [[ -z "${GOOGLE_SERVER_CLIENT_ID:-}" ]]; then
  echo "run_with_nextjs_env: AUTH_GOOGLE_ID missing in $NEXT_ROOT/.env.local or .env.vercel.production.local" >&2
  echo "Run: (cd $NEXT_ROOT && npm run env:pull)  or  npm run vercel:env-pull-production" >&2
  exit 1
fi

API_ORIGIN=""
if [[ -n "${ENV_FILE:-}" ]]; then
  API_ORIGIN="$(extract_kv NEXT_PUBLIC_APP_URL "$ENV_FILE" 2>/dev/null || true)"
  if [[ -z "${API_ORIGIN:-}" ]]; then
    API_ORIGIN="$(extract_kv VERCEL_URL "$ENV_FILE" 2>/dev/null || true)"
  fi
fi
if [[ -z "${API_ORIGIN:-}" ]]; then
  API_ORIGIN="https://hacklens.vercel.app"
elif [[ "$API_ORIGIN" != http* ]]; then
  API_ORIGIN="https://${API_ORIGIN}"
fi

if [[ -z "${JAVA_HOME:-}" ]]; then
  for cand in \
    "/home/neosoft/jdk-17.0.13+11" \
    "/usr/lib/jvm/java-17-openjdk-amd64" \
    "/usr/lib/jvm/java-17-amazon-corretto" \
    "$HOME/.jdks/corretto-17.0.13"; do
    if [[ -x "${cand:-}/bin/java" ]]; then
      export JAVA_HOME="$cand"
      break
    fi
  done
fi

cd "$FLUTTER_ROOT"
exec flutter run \
  --dart-define=GOOGLE_SERVER_CLIENT_ID="$GOOGLE_SERVER_CLIENT_ID" \
  --dart-define=API_ORIGIN="$API_ORIGIN" \
  "$@"
