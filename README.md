# claude-queue

Queue up Claude Code tasks and run them one at a time. Each task starts only
after the previous one has fully finished.

## Install

```sh
git clone <this repo> ~/claude-queue
~/claude-queue/bin/claude-queue install
```

Needs `bash`, `jq`, and `claude`.

## Use

Inside any Claude session, when you think of the next thing, type:

```
/q write tests for the login page
/q add a logout button
/q clean up unused imports
```

Each time Claude finishes, it picks up the next task by itself. When the queue
is empty it stops as normal. Bare `/q` shows what's pending, and
`claude-queue auto off` stops the chaining for that project.

Or skip the session and run the queue headless:

```sh
claude-queue add "write tests for the login page"
claude-queue add "add a logout button"
claude-queue run                                   # or: run --dangerously-skip-permissions
```

## Commands

```
add <task>     queue a task (or pipe it on stdin)
list           show pending tasks
rm <n>         remove task n
run [args]     run tasks with claude -p until the queue is empty; args go to claude
auto on|off    let an interactive session pick up tasks when it finishes
install        PATH symlink, Stop hook in ~/.claude/settings.json, /q command
```

Tasks live in `./.claude-queue/pending/` as plain markdown files. Finished ones
move to `done/`; headless run output goes to `logs/`. A failed headless run
stops the queue and leaves the task in place so `run` retries it.
