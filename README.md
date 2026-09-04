# claude-queue

Run Claude Code tasks **one after another**. Queue up the next feature or a
backlog of clean-up tasks while the current one is running; each task starts
only after the previous one has fully finished.

Tasks are plain markdown files in `.claude-queue/pending/`, so you can edit
and reorder them with any tool. Nothing runs in parallel.

## Install

```sh
git clone <this repo> ~/claude-queue
~/claude-queue/bin/claude-queue install
```

`install` does three things, once, so the queue works in **any project and any
terminal**:

1. symlinks `claude-queue` into a directory on your PATH
2. adds a Stop hook to `~/.claude/settings.json` (user level, so it's active in
   every project; it only chains tasks where you've run `claude-queue auto on`)
3. installs a `/queue` slash command into `~/.claude/commands/`, so inside any
   Claude session you can type `/queue add write tests for the parser`

Needs `bash`, `jq`, and the `claude` CLI on your PATH. The queue itself is
per project: it lives in `./.claude-queue/` of whatever directory you're in.

## Two ways to use it

### 1. Batch mode (headless, `claude -p`)

Queue tasks from any project directory, then run them:

```sh
cd ~/code/my-app
claude-queue add "Add a /health endpoint that returns build SHA and uptime"
claude-queue add "Write tests for the /health endpoint"
claude-queue add -f backlog/cleanup-imports.md      # longer prompt from a file
claude-queue list

claude-queue run            # runs each task to completion, in order
claude-queue run -c         # chain in one session so task N sees what task N-1 did
claude-queue run -k         # keep going past failures
claude-queue run -y         # --dangerously-skip-permissions (only in a sandbox you trust)
```

Each run's output is saved to `.claude-queue/logs/<id>-<slug>.log`. Finished
tasks move to `done/`, failed ones to `failed/` (`claude-queue retry <id>` puts
one back). By default the queue stops at the first failure so a broken step
doesn't cascade.

Headless runs use `--permission-mode acceptEdits`. Set
`CLAUDE_QUEUE_PERMISSION_MODE` or pass extra flags after `--`:

```sh
claude-queue run -- --allowedTools "Bash(npm test)" --model claude-sonnet-5
```

### 2. Interactive mode (Stop hook)

Keep working in a normal `claude` session and let the queue feed it the next
task each time Claude finishes:

```sh
cd ~/code/my-app
claude-queue auto on        # hook was installed globally by `claude-queue install`
claude                      # start (or keep using) your interactive session
```

From another terminal, `claude-queue add "..."` whenever you think of the next
thing. When Claude finishes its current turn, the hook hands it the first
pending task; when the queue is empty, Claude stops as usual. `claude-queue auto
off` pauses chaining without removing the hook.

## Dashboard

```sh
claude-queue watch
```

A live terminal view: the task currently running with elapsed time and the
tail of its log, the pending list, and done/failed counts. Refreshes every
two seconds; `q` quits. Run it in a split pane next to `claude-queue run` or
your interactive session.

## Commands

| command | what it does |
|---|---|
| `add <prompt>` / `add -f file` / stdin | queue a task |
| `list` | pending tasks in run order |
| `show <id>` / `edit <id>` | view or edit a task's prompt |
| `move <id> top\|bottom` | reorder |
| `rm <id>` / `clear` | drop one / all pending tasks |
| `run [-c] [-k] [-y] [-n] [-- claude args]` | run the queue |
| `retry <id>` | move a failed task back to pending |
| `status` / `log <id>` | counts, or a task's saved output |
| `watch` | live dashboard |
| `auto on\|off` | interactive-mode chaining |
| `install` / `install-hook` | one-time setup / project-only Stop hook |
| `/queue <args>` (inside Claude) | same commands from a Claude session |

`CLAUDE_QUEUE_DIR` overrides the queue location (default `./.claude-queue`).
Add `.claude-queue/` to your project's `.gitignore`.

## Layout

```
.claude-queue/
  pending/0001-add-a-health-endpoint.md
  done/
  failed/
  logs/0001-add-a-health-endpoint.log
  running         # present while `run` has a task in flight
  auto            # present = Stop hook chaining enabled
```
