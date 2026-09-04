#!/usr/bin/env bash
set -euo pipefail
Q="${CLAUDE_QUEUE_DIR:-$PWD/.claude-queue}"
cat >/dev/null
[ -z "${CLAUDE_QUEUE_BATCH:-}" ] || exit 0
ls "$Q/pending"/*.md >/dev/null 2>&1 || exit 0
mkdir -p "$Q/stale"
mv "$Q/pending"/*.md "$Q/stale/"
