# claude-queue

Queue up tasks for [Claude Code](https://claude.com/claude-code) while it's busy.
Each one starts automatically when the current task finishes. One at a time, never in parallel.

## Install

```sh
git clone https://github.com/nathanjcx/claude-queue ~/claude-queue
~/claude-queue/bin/claude-queue install
```

Requires `bash`, `jq`, and the `claude` CLI. Restart any open Claude sessions afterwards.

## Use

While Claude is working on something, type the next thing into the same session:

```
/q write tests for the login page
/q add a logout button
/q clean up unused imports
```

That's it. When Claude finishes what it's doing, it picks up the first queued task.
When that's done, the next one. When the queue is empty, it stops and waits for you as usual.

- `/q` on its own shows what's pending.
- `claude-queue rm 2` removes the second task.
- `claude-queue auto off` pauses the chaining for that project.

## Headless

Don't want a session open? Queue from the shell and run the whole list:

```sh
claude-queue add "write tests for the login page"
claude-queue add "add a logout button"
claude-queue run
```

Each task runs with `claude -p` to completion, output is logged to `.claude-queue/logs/`.
Extra flags go straight to `claude`, e.g. `claude-queue run --dangerously-skip-permissions`.
If a task fails the queue stops and leaves it in place, so `run` again retries it.

## How it works

Tasks are markdown files in `./.claude-queue/pending/`. A Stop hook in
`~/.claude/settings.json` runs whenever Claude finishes a turn. If the project has
chaining on and a task is pending, the hook moves it to `done/` and tells Claude to
start it instead of stopping. Add `.claude-queue/` to your `.gitignore`.

## Commands

```
add <task>     queue a task (or pipe it on stdin)
list           show pending tasks
rm <n>         remove task n
run [args]     run tasks with claude -p until the queue is empty; args go to claude
auto on|off    let an interactive session pick up tasks when it finishes
install        PATH symlink, Stop hook in ~/.claude/settings.json, /q command
```
