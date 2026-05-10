#!/usr/bin/env bash
# Pull Next.js env from Vercel into sonar-hack-app/.env.local (needs `vercel login` once).

set -euo pipefail

NEXT_ROOT="$(cd "$(dirname "$0")/../../sonar-hack-app" && pwd)"
cd "$NEXT_ROOT"

if [[ -f package.json ]] && grep -q '"env:pull"' package.json 2>/dev/null; then
  exec npm run env:pull
fi

if ! command -v vercel >/dev/null 2>&1; then
  echo "Install Vercel CLI: npm i -g vercel" >&2
  exit 1
fi

exec vercel env pull .env.local -y
