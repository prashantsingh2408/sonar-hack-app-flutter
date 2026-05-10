#!/usr/bin/env bash
# Source from build/run scripts. Exports GOOGLE_SERVER_CLIENT_ID, API_ORIGIN,
# JAVA_HOME (optional), FLUTTER_ROOT, NEXT_ROOT.
# Usage: source "$(dirname "$0")/load_next_env.sh"

_TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export FLUTTER_ROOT="$(cd "$_TOOL_DIR/.." && pwd)"
export NEXT_ROOT="$(cd "$FLUTTER_ROOT/../sonar-hack-app" && pwd)"

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

export GOOGLE_SERVER_CLIENT_ID=""
_ENV=""
for f in "$NEXT_ROOT/.env.local" "$NEXT_ROOT/.env.vercel.production.local"; do
  [[ -f "$f" ]] || continue
  if v="$(extract_kv AUTH_GOOGLE_ID "$f" 2>/dev/null)" && [[ -n "${v:-}" ]]; then
    _ENV="$f"
    GOOGLE_SERVER_CLIENT_ID="$v"
    break
  fi
done
export GOOGLE_SERVER_CLIENT_ID

export API_ORIGIN="https://hacklens.vercel.app"
if [[ -n "${_ENV:-}" ]]; then
  _u="$(extract_kv NEXT_PUBLIC_APP_URL "$_ENV" 2>/dev/null || true)"
  if [[ -z "${_u:-}" ]]; then
    _u="$(extract_kv VERCEL_URL "$_ENV" 2>/dev/null || true)"
  fi
  if [[ -n "${_u:-}" ]]; then
    API_ORIGIN="$_u"
    [[ "$API_ORIGIN" == http* ]] || API_ORIGIN="https://${API_ORIGIN}"
  fi
fi
export API_ORIGIN

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
