#!/usr/bin/env bash
set -euo pipefail
Q="${CLAUDE_QUEUE_DIR:-$PWD/.claude-queue}"
cat >/dev/null
[ -z "${CLAUDE_QUEUE_BATCH:-}" ] && [ -f "$Q/auto" ] || exit 0
f=$(ls "$Q/pending"/*.md 2>/dev/null | head -1) && [ -n "$f" ] || exit 0
mv "$f" "$Q/done/"
jq -n --arg p "$(cat "$Q/done/$(basename "$f")")" '{decision:"block", reason:("Previous task complete. Next queued task:\n\n" + $p)}'
