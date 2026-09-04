---
description: Queue a task for later — /q <task>. /q lists the queue, /q rm picks a task to remove.
allowed-tools: Bash(claude-queue:*), AskUserQuestion
---
The user ran `/q $ARGUMENTS`. The claude-queue CLI already executed it; here is the output:

```
!`claude-queue q $ARGUMENTS`
```

If the output starts with `PICK_TO_REMOVE`: use the AskUserQuestion tool once, question "Remove which task?", with one option per listed task (label = the task text, trimmed to a few words; description = the id). If there are more than 4 tasks, show the first 4 and mention the rest can be typed as an id via Other. When the user picks one, run `claude-queue rm <id>` with Bash and confirm in one line.

Otherwise report the result to the user in one short line.

Never start working on a queued task now — queued tasks run later, one at a time, after the current work is finished.
