#!/usr/bin/env bash
# Pull Next.js env from Vercel into sonar-hack-app (needs `vercel login` once).
# Runs `npm run env:pull`; if AUTH_GOOGLE_ID is still missing, runs production pull.
# Uses the same resolution rules as load_next_env.sh.

set -euo pipefail

_TOOL_DIR="$(cd "$(dirname "$0")" && pwd)"
_FLUTTER_ROOT="$(cd "$_TOOL_DIR/.." && pwd)"
_NEXT_ROOT="$(cd "$_FLUTTER_ROOT/../sonar-hack-app" && pwd)"

if [[ ! -f "$_NEXT_ROOT/package.json" ]]; then
  echo "pull_vercel_env: expected Next app at $_NEXT_ROOT" >&2
  exit 1
fi

cd "$_NEXT_ROOT"

if grep -q '"env:pull"' package.json 2>/dev/null; then
  npm run env:pull
else
  if ! command -v vercel >/dev/null 2>&1; then
    echo "Install Vercel CLI: npm i -g vercel" >&2
    exit 1
  fi
  vercel env pull .env.local -y
fi

# shellcheck source=load_next_env.sh
source "$_FLUTTER_ROOT/tool/load_next_env.sh"

if [[ -z "${GOOGLE_SERVER_CLIENT_ID:-}" ]]; then
  echo "AUTH_GOOGLE_ID not found in .env.local; pulling production env → .env.vercel.production.local ..."
  if grep -q '"vercel:env-pull-production"' package.json 2>/dev/null; then
    npm run vercel:env-pull-production
  else
    vercel env pull .env.vercel.production.local --environment production -y
  fi
  # shellcheck source=load_next_env.sh
  source "$_FLUTTER_ROOT/tool/load_next_env.sh"
fi

if [[ -z "${GOOGLE_SERVER_CLIENT_ID:-}" ]]; then
  echo "pull_vercel_env: AUTH_GOOGLE_ID still missing after pull." >&2
  echo "Add AUTH_GOOGLE_ID (and AUTH_GOOGLE_SECRET for Next) in Vercel → Project → Settings → Environment Variables," >&2
  echo "or copy from Google Cloud OAuth Web client into $_NEXT_ROOT/.env.local — see $_NEXT_ROOT/.env.example" >&2
  exit 1
fi

echo "Env OK for Flutter (from Next repo env files):"
echo "  AUTH_GOOGLE_ID        → GOOGLE_SERVER_CLIENT_ID (dart-define)"
echo "  NEXT_PUBLIC_APP_URL / VERCEL_URL → API_ORIGIN (dart-define, currently: $API_ORIGIN)"
