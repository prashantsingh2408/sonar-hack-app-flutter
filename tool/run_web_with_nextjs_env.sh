#!/usr/bin/env bash
# Same as run_with_nextjs_env.sh but opens Chrome (web).

set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$DIR/run_with_nextjs_env.sh" -d chrome "$@"
