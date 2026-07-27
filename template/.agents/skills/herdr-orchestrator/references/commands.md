# Herdr commands

Load when you need exact flags, JSON paths, or the risk level of a command.
**Verified against the installed binary** — run `herdr --version` and
`herdr <group> --help`; the installed binary is the source of truth for syntax, ahead
of any docs (including this file).

## Risk classification

| Risk | Commands | Rule |
|---|---|---|
| Safe | `*/list`, `*/get`, `pane current`, `pane read`, `agent read`, `agent list`, `agent get`, `agent explain`, `api snapshot`, `integration status`, `*/wait` | Run freely |
| Creates state | `workspace create`, `tab create`, `pane split`, `worktree create`, `agent start`, `agent rename` | Fine within the user's stated goal |
| Sends input | `pane run`, `pane send-text`, `pane send-keys` | Fine to your own lanes; never type into a pane the user is using. `agent prompt`/`agent send-keys` may not work — see below |
| Destructive | `workspace close`, `worktree remove`, `agent release`, `server stop`, `integration install/uninstall` | **Ask the user first** |
| Cleanup | `pane close`, `tab close` | Your own finished lanes: close them. Anything the user opened, or an agent still `working`: ask first |
| Focus-stealing | any `focus`, `--focus`, `pane zoom`, `pane swap`, `pane move` | Avoid mid-batch; always prefer `--no-focus` |

## Layout

```bash
herdr workspace create --cwd <path> --label <text> --no-focus
# → .result.workspace, .result.tab, .result.root_pane

herdr tab create --cwd <path> --label <text> --no-focus
# → .result.tab, .result.root_pane

herdr pane split [PANE_ID|--current] --direction <right|down> [--ratio 0.5] [--cwd P] [--env K=V] --no-focus
# → .result.pane          → pane ID at .result.pane.pane_id
```

`pane move` changes the workspace-qualified pane ID. Continue from `.result.move_result.pane.pane_id`; the old value stays at `.result.move_result.previous_pane_id`. A wait already running against the old ID dies with `agent_not_running`.

## Agents

```bash
herdr agent list                       # → .result.agents[]
herdr agent get <target>               # → .result.agent
herdr agent start <name> --kind <kind> --pane <id> [--timeout MS] [-- <agent args>]
herdr agent rename <target> <name>
herdr agent explain <target> [--json]  # why Herdr classified this state
herdr agent focus <target>             # bring the pane into view
herdr agent attach <target> [--takeover]  # hand the terminal to the user
```

<!-- CONFIG: `--kind` — use a kind whose integration is installed on your machine.
     Check `herdr integration status`. Common kinds herdr knows about:
     pi, claude, codex, gemini, cursor, devin, agy, cline, omp, mastracode,
     opencode, copilot, kimi, kiro, droid, amp, grok, hermes, kilo, qodercli, maki.
     Only installed kinds report trustworthy lifecycle state; others fall back to
     screen detection and report `unknown` more often. -->

Everything after `--` is passed to the agent binary:

```bash
herdr agent start api --kind <kind> --pane "$p" -- \
  --model <provider>/<id> --thinking high -n api
```

`agent start` needs the pane at its interactive shell prompt, and returns only once the expected agent is detected and ready. Startup timeout defaults to 30000, must be >3000 and ≤300000.

## Input

```bash
herdr agent prompt <target> "<text>" [--wait] [--until <status>]... [--timeout MS]   # may be broken — see main-agent-launch.md
herdr agent send-keys <target> <keys>       # may be broken
herdr pane run <pane_id> <command>...
herdr pane send-text <pane_id> "<text>"     # no Enter
herdr pane send-keys <pane_id> <keys>
```

**Agent-targeted input may not work on your setup.** If the agent binary on PATH is a
launcher that spawns the real CLI as a child (e.g. the AMP-Pi launcher), the pane's
foreground group holds two processes and Herdr rejects the target. Both `agent prompt`
and `agent send-keys` then return `agent_not_ready`. Use the pane instead:

```bash
herdr pane send-text "$pane" "<brief>"
herdr pane send-keys "$pane" enter
```

`pane send-keys` takes `esc`, `enter`, `up`, `down`, `ctrl+c`. Keep the pane ID for the whole life of the lane, not just the name. `agent wait`, `read`, `get`, `rename`, `focus`, `attach` are unaffected.

## Waiting

```bash
herdr agent wait <target> [--until idle|working|blocked|done|unknown]... [--timeout MS]
herdr pane wait-output <pane_id> <--match TEXT|--regex PATTERN> [--source S] [--lines N] [--timeout MS]
```

Defaults with no `--until`: `idle`, `done`, `blocked`. Repeat `--until` for several. `unknown` only matches when named explicitly. **No `--timeout` means indefinite** — always pass one.

`agent wait` returns immediately if the state already matches. `pane wait-output` searches the existing snapshot first, so text already on screen matches; `--regex` is Rust syntax, one line at a time. It knows nothing about agent lifecycle — use it for servers, tests, builds.

## Reading

```bash
herdr agent read <target> [--source S] [--lines N] [--format text|ansi]
herdr pane read <pane_id>  [--source S] [--lines N] [--raw]
```

| `--source` | Use for |
|---|---|
| `recent` | default, last 80 rendered rows |
| `recent-unwrapped` | prose and agent answers — **can be empty**, see below |
| `visible` | current screen, after the agent scrolled |
| `detection` | exactly what Herdr classified state on, always plain text |

For recent sources `--lines N` picks the last N rendered rows (default 80). For `visible`/`detection`, omitting `--lines` returns the whole snapshot. Socket API returns text at `.result.read.text`.

**With agents that render on the alternate screen (pi does), `recent` and `recent-unwrapped` can return nothing** — the rows never reach host scrollback. `pane read --source recent` can be empty for the same reason. Use `--source visible`; `detection` works but shows only the footer, never the answer.

## Worktrees

```bash
herdr worktree create --cwd <repo> --branch <name> --base <ref> --no-focus --json
herdr worktree list
herdr worktree remove ...    # destructive, ask first
```

## Inspection

```bash
herdr status                 # client + server
herdr api snapshot           # entire live session — large, prefer agent list
herdr integration status     # which agents have state hooks installed
herdr pane process-info <id> # what is actually running in a pane
```

## Result paths and exit codes

- `agent start` / `agent wait` / `agent rename` → `.result.agent`
- `pane wait-output` → `.result.pane_id`, `.result.matched_line`, `.result.read`
- `pane split` → `.result.pane`
- `workspace create` → `.result.workspace`, `.result.tab`, `.result.root_pane`

Exit 1 = server error or timeout, JSON error on stderr. Exit 2 = invalid CLI syntax.

Every command prints JSON on one line — pipe through `jq -r`, never parse by eye.
