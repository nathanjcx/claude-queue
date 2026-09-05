---
description: Queue a task to run after the current work finishes. /q <task> adds, bare /q lists.
allowed-tools: Bash(claude-queue:*)
---
The user ran `/q $ARGUMENTS`. Output:

```
!`claude-queue q <<'CLAUDE_QUEUE_EOF'
$ARGUMENTS
CLAUDE_QUEUE_EOF`
```

Report the result in one short line: what was queued and how many tasks are pending in total. Do not start any queued task now; they run one at a time after the current work is finished.
