#!/usr/bin/env bash
# Claude Code Stop hook. When Claude finishes a turn in an interactive session
# and `claude-queue auto on` is set, hand it the next queued task instead of
# letting it stop. The chain ends by itself when the queue is empty.
set -euo pipefail

QUEUE_DIR="${CLAUDE_QUEUE_DIR:-$PWD/.claude-queue}"
cat >/dev/null                             # consume hook input; we don't need it

[ -z "${CLAUDE_QUEUE_BATCH:-}" ] || exit 0 # `claude-queue run` owns the queue; stay out
[ -f "$QUEUE_DIR/auto" ] || exit 0         # auto-chain disabled
next=$(ls "$QUEUE_DIR/pending"/*.md 2>/dev/null | head -1 || true)
[ -n "$next" ] || exit 0                   # queue empty: let Claude stop

mkdir -p "$QUEUE_DIR/done"
mv "$next" "$QUEUE_DIR/done/"

prompt=$(cat "$QUEUE_DIR/done/$(basename "$next")")
jq -n --arg p "$prompt" --arg n "$(basename "$next" .md)" \
  '{decision:"block", reason:("The previous task is complete. Start the next queued task (" + $n + "):\n\n" + $p)}'
