#!/usr/bin/env bash
# Smoke test for claude-queue. Runs against a throwaway queue dir; never calls `claude`.
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
Q="$HERE/../bin/claude-queue"
TMP=$(mktemp -d)
export CLAUDE_QUEUE_DIR="$TMP/.claude-queue"
trap 'rm -rf "$TMP"' EXIT

pass=0; fail=0
ok()   { pass=$((pass + 1)); echo "PASS  $1"; }
bad()  { fail=$((fail + 1)); echo "FAIL  $1"; [ -n "${2:-}" ] && printf '      got: %s\n' "$2"; }

# assert_eq <name> <expected> <actual>
assert_eq() { [ "$2" = "$3" ] && ok "$1" || bad "$1" "$3 (want: $2)"; }
# assert_has <name> <needle> <haystack>
assert_has() { case "$3" in *"$2"*) ok "$1" ;; *) bad "$1" "$3" ;; esac; }
# assert_file <name> <path>
assert_file() { [ -e "$2" ] && ok "$1" || bad "$1" "missing $2"; }
# assert_nofile <name> <path>
assert_nofile() { [ ! -e "$2" ] && ok "$1" || bad "$1" "exists $2"; }

pending() { ls "$CLAUDE_QUEUE_DIR/pending" 2>/dev/null | tr '\n' ' ' | sed 's/ $//'; }

# --- add: argument, file, stdin ------------------------------------------
"$Q" add "Add a health endpoint" >/dev/null
assert_file "add from args creates pending file" "$CLAUDE_QUEUE_DIR/pending/0001-add-a-health-endpoint.md"
assert_eq  "add from args stores prompt" "Add a health endpoint" "$(cat "$CLAUDE_QUEUE_DIR/pending/0001-add-a-health-endpoint.md")"

printf 'Clean up imports\n\nAcross src/, remove unused imports.\n' > "$TMP/task.md"
"$Q" add -f "$TMP/task.md" >/dev/null
assert_file "add -f creates pending file" "$CLAUDE_QUEUE_DIR/pending/0002-clean-up-imports.md"
assert_eq  "add -f keeps multi-line body" "3" "$(wc -l < "$CLAUDE_QUEUE_DIR/pending/0002-clean-up-imports.md" | tr -d ' ')"

printf 'Write tests for health\n' | "$Q" add >/dev/null
assert_file "add from stdin creates pending file" "$CLAUDE_QUEUE_DIR/pending/0003-write-tests-for-health.md"

out=$("$Q" add "   " 2>&1); rc=$?
assert_eq  "add rejects whitespace-only prompt" "1" "$rc"

# --- list ------------------------------------------------------------------
out=$("$Q" list)
assert_eq  "list shows three rows" "3" "$(printf '%s\n' "$out" | wc -l | tr -d ' ')"
assert_has "list row has position, id, title" " 1. 0001  Add a health endpoint" "$out"
assert_has "list row order follows id" " 3. 0003  Write tests for health" "$out"

# --- move top / bottom -----------------------------------------------------
"$Q" move 3 top >/dev/null
assert_eq  "move top renumbers queue" "0001-write-tests-for-health.md 0002-add-a-health-endpoint.md 0003-clean-up-imports.md" "$(pending)"
"$Q" move 1 bottom >/dev/null
assert_eq  "move bottom renumbers queue" "0001-add-a-health-endpoint.md 0002-clean-up-imports.md 0003-write-tests-for-health.md" "$(pending)"
out=$("$Q" move 1 sideways 2>&1); rc=$?
assert_eq  "move rejects bad direction" "1" "$rc"

# --- rm by id and by position ---------------------------------------------
"$Q" add "Fourth task" >/dev/null          # ids: 1 2 3 4
"$Q" rm 0002 >/dev/null
assert_nofile "rm by 4-digit id removes task" "$CLAUDE_QUEUE_DIR/pending/0002-clean-up-imports.md"
"$Q" rm 3 >/dev/null                       # id 0003 still exists, so this is by id
assert_nofile "rm by short id removes task" "$CLAUDE_QUEUE_DIR/pending/0003-write-tests-for-health.md"
# remaining: 0001, 0004. position 2 == id 0004 (no id 0002 exists any more)
"$Q" rm 2 >/dev/null
assert_nofile "rm by list position removes task" "$CLAUDE_QUEUE_DIR/pending/0004-fourth-task.md"
assert_eq  "rm leaves the rest intact" "0001-add-a-health-endpoint.md" "$(pending)"
out=$("$Q" rm 9 2>&1); rc=$?
assert_eq  "rm unknown id fails" "1" "$rc"
assert_has "rm unknown id explains" "no task '9'" "$out"

# --- run -n (dry run) -------------------------------------------------------
"$Q" add "Second dry task" >/dev/null
out=$("$Q" run -n 2>&1); rc=$?
assert_eq  "run -n exits 0" "0" "$rc"
assert_has "run -n reports both tasks" "queue drained: 2 ran, 0 failed" "$out"
assert_eq  "run -n empties pending" "" "$(pending)"
assert_eq  "run -n moves tasks to done" "2" "$(ls "$CLAUDE_QUEUE_DIR/done" | wc -l | tr -d ' ')"

# --- retry -------------------------------------------------------------------
mv "$CLAUDE_QUEUE_DIR/done/0001-add-a-health-endpoint.md" "$CLAUDE_QUEUE_DIR/failed/"
"$Q" retry 1 >/dev/null
assert_file "retry moves failed task back to pending" "$CLAUDE_QUEUE_DIR/pending/0001-add-a-health-endpoint.md"
assert_nofile "retry clears it from failed" "$CLAUDE_QUEUE_DIR/failed/0001-add-a-health-endpoint.md"
out=$("$Q" retry 1 2>&1); rc=$?
assert_eq  "retry on non-failed id fails" "1" "$rc"

# --- status / next id after done ------------------------------------------
assert_has "status counts pending and done" "pending 1   done 1   failed 0" "$("$Q" status)"
"$Q" add "Next id skips used ones" >/dev/null
assert_file "next id counts done/ too" "$CLAUDE_QUEUE_DIR/pending/0003-next-id-skips-used-ones.md"

# --- q (slash-command entry point) ----------------------------------------
"$Q" q Some queued text >/dev/null
assert_file "q <text> adds a task" "$CLAUDE_QUEUE_DIR/pending/0004-some-queued-text.md"
assert_has "q with no args lists" "0004  Some queued text" "$("$Q" q)"
assert_has "q rm without tty emits pick list" "PICK_TO_REMOVE" "$("$Q" q rm | cat)"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
