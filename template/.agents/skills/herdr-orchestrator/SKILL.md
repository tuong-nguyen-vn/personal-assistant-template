---
name: herdr-orchestrator
description: Orchestrate main agents with the Herdr CLI — pick a model per lane, start each agent in its own pane, prompt it, wait on lifecycle state, handle blocked agents, and report. Use when delegating any real work to another agent, running several in parallel, monitoring a batch, or reading another pane's output. Every agent started this way is a full main agent, not a subagent. Only usable from inside a Herdr-managed pane (HERDR_ENV=1).
---

# Herdr orchestrator

Herdr is a terminal workspace manager for AI coding agents. This skill covers driving them: pick models, create panes, start agents, wait, decide, report.

> **This is a template.** Before it is useful you must fill in the machine-specific
> values marked `<!-- CONFIG -->` in each file, and complete `references/models.config.md`.
> See `CONFIG.md` at the project root for a walkthrough. Lines tagged
> `<!-- MACHINE -->` describe quirks of a specific setup — verify they apply to you,
> or delete them.

## Main agents, not subagents

Every agent you start here is a **main agent**: its own process, model, context window, session file, and terminal. You talk to it the way the user talks to you — a real conversation you can follow up on, and one the user can attach to.

```
user
 └─ you (main agent, this pane)
     ├─ herdr pane → pi main agent, claude-sonnet-5
     ├─ herdr pane → pi main agent, claude-sonnet-5
     └─ herdr pane → pi main agent, swe-1-7
```

**Do not use the `subagent` tool for work that belongs in a pane.** A subagent returns one string and dies: no model choice, no follow-up, nothing the user can attach to. Use it only for a throwaway one-shot lookup that nobody will ever revisit.

## Guardrail — run this first, every time

```bash
[ "$HERDR_ENV" = "1" ] && echo ok || echo "NOT in a Herdr pane"
```

Not `ok` → **stop**. Tell the user you are not inside a Herdr-managed pane and do not touch the socket. Everything below assumes it passed.

Safe without asking: creating workspaces/tabs/panes, starting agents, reading output, waiting.
Ask first: closing a pane, killing an agent, `integration install/uninstall`, `server stop`, answering an approval prompt that is destructive or outside what the user already approved.

## Model

```
workspace (w6) ─→ tab (w6:t1) ─→ pane (w6:p2) ─→ agent
```

A pane is a terminal; it exists with or without an agent. An agent is the recognized process inside it. `agent start` never creates layout — split first, then start into the returned pane ID.

Lifecycle states: `working` · `idle` · `blocked` · `done` · `unknown`.
`blocked` = an approval or question UI is on screen, someone must answer.
`unknown` = an agent is present but unclassifiable. **Not proof of success.**

Names match `[a-z][a-z0-9_-]{0,31}`, must be unique among live agents, and are released when the agent exits. `agent wait`/`read`/`get` accept a name or a pane ID; **sending input needs the pane ID**, because it goes through `pane send-text`. Keep both for every lane.

## Scoping — one task, one agent, one space

- **One agent per task, one task per agent.** Work a task inside a single agent/session until it's done. A new, independent task gets a fresh scope — either `/new` a session in the same pane or start a new agent — never keep piling unrelated tasks onto one agent's context. Just as important the other way: don't fragment one task across many agents either — split lanes only when the work is genuinely parallel and independent, not by default.
- **One Herdr space per project.** Reuse the project's existing space if one already matches (check `herdr workspace list` first); only create a new space when none fits.
- **Tabs split work streams inside that space** (e.g. an HRM tab and an Attendance tab inside the ERP space), not new spaces.
- **Cap panes per task at 2–4.** If a task needs more parallelism than that, it's really multiple tasks — split into separate tabs/sessions instead of stacking panes.

## Workflow

1. Guardrail check.
2. **Survey the project's space.** Before planning, read what is already there: `workspace list` → find the project's space → `tab list` → `pane list` → `pane read` on non-agent panes whose cwd is deep in the project (likely dev servers; `agent_status: unknown`). Note what is running, what is idle, and any errors visible on screen. This is the operational context you feed into lane prompts — don't plan blind.
3. **Plan lanes** so no two agents write the same files → load `references/batch.md`. Keep the batch within the pane cap above.
4. **Pick a model per lane** → load `references/model-routing.md`. Use `references/models.config.md` for the `provider/id` strings available on this machine.
5. **Reuse the project's space; create a tab for the batch inside it.** Its root pane is your first lane; split inside that tab for the rest. Never split into the pane you are talking to the user in.
6. **Start agents** into panes sitting at a shell prompt → load `references/main-agent-launch.md`.
7. **Prompt** each lane with a self-contained brief including its ownership boundary.
8. **Wait and read** → load `references/monitoring.md`. For >1 lane prefer `bin/wait-any` (event-driven, order-independent) over serial `agent wait`.
9. **Report** one table, with each lane's name so the user can attach. Verify claims before repeating them.
10. **Close the batch tab** once every lane is summarized.

Minimal end-to-end (illustrative — replace `--kind` and the agent flags with those of
the CLI the user routes the lane through):

```bash
base=$(herdr tab create --cwd ~/projects/app --label review --no-focus | jq -r '.result.root_pane.pane_id')
herdr agent start reviewer --kind <kind> --pane "$base" -- \
  --model <provider>/<id> <…agent-specific flags…>
herdr pane send-text "$base" "Review the current diff. Do not edit files. Answer in under 20 lines."
herdr pane send-keys "$base" enter
herdr agent wait reviewer --until idle --until done --timeout 600000
herdr agent read reviewer --source visible --lines 40
```

> **Why `pane send-text` and not `agent prompt`?** If the chosen CLI is a launcher that
> spawns a child process (AMP-Pi is one example; other wrappers exist), agent-targeted
> input fails with `agent_not_ready`. Many agents also render on an alternate screen so
> scrollback reads return nothing. The pane-based commands work regardless of CLI.
> `references/main-agent-launch.md` explains and tells you how to confirm.

## Context discipline

Terminal output is unbounded; your context is not. This section is why this skill exists.

- **Wait, never poll.** `agent wait` blocks on state; `bin/wait-any` blocks on events for several lanes at once. Reading in a loop burns context for nothing.
- **Read only the pane that changed**, never all panes.
- **Start at `--lines 40` on `--source visible`.** If scrollback is empty on your setup (pi on the alternate screen), `--lines` tails the current screen — an answer longer than one screenful is unrecoverable. Ask for short answers, do not raise `--lines` and hope.
- **Ask for short answers in the prompt.** Cheaper than reading long ones.
- **Summarize each lane once it settles**, then stop re-reading it.
- **Always `--no-focus`** when splitting. Stealing the user's focus mid-work is hostile.
- **Always set `--timeout`.** Wait commands otherwise block forever.

## Layout hygiene — the user has to read this screen

- **Never split into the tab you are talking to the user in.** Six panes stacked beside their session leaves every one of them three lines tall and unreadable. One `tab create` per batch, split inside it.
- **A pane you are done with is closed, not abandoned.** Close each lane once you have summarized it. Leaving dead panes around while opening new ones shrinks every live pane.
- **Ask before closing a pane the user opened**, or one whose agent is still `working`. Your own finished lanes you close yourself.
- One-off probes and experiments: same rule, one tab, closed when done.

## Load a reference only when you reach that step

| Situation | File |
|---|---|
| Which model for this lane, routing logic | `references/model-routing.md` |
| Per-model strengths, failure modes, prompt shapes (deep) | `../../../models/catalog.md` |
| The `provider/id` strings available here, which carries which model | `references/models.config.md` |
| Launch flags, prompting, hand-off to the user | `references/main-agent-launch.md` |
| Splitting work, how many agents, worktree isolation, prompt shape | `references/batch.md` |
| Watching a batch, handling `blocked`, reporting to the user | `references/monitoring.md` |
| Exact flags, JSON result paths, risk classification | `references/commands.md` |
| Stalls, empty reads, timeouts, wrong state detection | `references/troubleshooting.md` |

Do not preload these. One file, when the task is at that step.

## Environment <!-- CONFIG: fill in, then delete this block once verified -->

Verify your own setup once and record it here. Run these and paste the results, then
remove this block and leave a one-line summary (e.g. "Herdr 0.7.5, `pi` integration
installed, AMP-Pi launcher → use `pane send-text`"):

```bash
herdr --version                                   # CONFIG: version
which herdr                                        # CONFIG: path
herdr integration status                           # CONFIG: which agent kinds have state hooks
herdr status                                       # CONFIG: client + server, socket path
which jq                                           # CONFIG: needed to parse JSON output
# On pi specifically — do these return data or empty?
herdr agent read <some-pi-pane> --source recent --lines 5      # CONFIG: empty → alt-screen, use --source visible
```

Rule of thumb across all of this: `herdr <group> --help` on the installed binary is the
source of truth for syntax, ahead of any docs (including this skill).
