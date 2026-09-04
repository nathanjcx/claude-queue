---
description: Queue a task for later — /q <task>. Also /q list, /q rm <id>, /q move <id> top, /q status, /q auto on|off
allowed-tools: Bash(claude-queue:*)
---
The user ran `/q $ARGUMENTS`. The claude-queue CLI already executed it; here is the output:

```
!`claude-queue q $ARGUMENTS`
```

Report the result to the user in one short line. Do not start working on any queued task now — queued tasks run later, one at a time, after the current work is finished.
