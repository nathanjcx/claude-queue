---
description: Queue a task to run after the current work finishes. /q <task> adds, bare /q lists.
allowed-tools: Bash(claude-queue:*)
---
The user ran `/q $ARGUMENTS`. Output:

```
!`claude-queue q $ARGUMENTS`
```

Report the result in one short line. Do not start any queued task now; they run one at a time after the current work is finished.
