# Launching a main agent

Load when starting an agent in a pane. Every agent you start is a **full main agent**: its own process, model, context window, session file, and terminal. It is not a subagent of yours. You talk to it the way the user talks to you.

```
you (a main agent in a pane)
 └─ herdr pane → pi main agent  (own model, own context, own session)
 └─ herdr pane → pi main agent
```

Never use a harness `subagent`/`spawn_agent` tool for work that belongs in a pane. A subagent returns one string and dies; a main agent is addressable, resumable, and the user can attach to it.

## The launch line

```bash
herdr agent start <name> --kind <kind> --pane "$pane" -- \
  --model <provider>/<id> --thinking <level> -n <name>
```

Everything after `--` goes to the agent binary. `-n <name>` sets the session display name so the pane title reads the agent name + project, which is how the user tells them apart.

<!-- CONFIG: replace `--kind pi` with an integration you have installed
     (check `herdr integration status`). pi is the most common; use whichever
     kinds report installed. Uninstalled kinds fall back to screen detection
     and report `unknown` more often. -->

Add per-lane flags as needed (pi flags — adjust for your agent):

| Flag | Use |
|---|---|
| `-t read,grep,find,ls` | read-only lane (review, investigation) |
| `--append-system-prompt <text\|file>` | give the lane a role without replacing the agent's prompt |
| `-nc` | ignore project `AGENTS.md` — rarely right, the project rules usually should apply |
| `--session-dir <dir>` | keep a batch's sessions out of the main history |

## `--model` must carry the provider

A bare model id can resolve to the wrong provider and the agent boots into `Error: No API key found for <something>`. Two or more providers often carry the same model id (e.g. a GLM entry on two providers), and the bare id resolves unpredictably.

**Always write `provider/id`.** Look up the exact string for each canonical model in `references/models.config.md`. It is the source of truth for what your setup can actually run.

```bash
pi --list-models <search>     # source of truth on this machine
```

Check the pane's footer after start — it prints the model that actually loaded.

`--thinking` is honored on some providers and ignored on others (footer shows `off`).
`models.config.md` notes which is which for each of your providers. Do not route a
lane to a provider that ignores thinking when you wanted deep reasoning.

## Two things may be broken — route around them <!-- MACHINE: verify, then keep or delete -->

On some setups two agent-targeted features fail. **Verify before relying on them.**
The pane-based workarounds below work for everyone regardless.

### 1. Agent-targeted *input* may fail

```
herdr agent prompt <name> "..."     → agent_not_ready: no longer the pane foreground process
herdr agent send-keys <name> esc   → agent_not_ready (same cause)
```

This happens when the agent binary on PATH is a *launcher* that spawns the real CLI as
a child (e.g. the AMP-Pi launcher `@aaroncql/pim-agent`). The pane's foreground group
then holds two processes where Herdr expects one.

Confirm with `herdr pane process-info --pane <id>` — if you see two processes, the
agent-targeted input commands will not work.

The pane equivalents work regardless:

```bash
herdr pane send-text "$pane" "<the whole brief>"
herdr pane send-keys "$pane" enter      # also esc, ctrl+c, up, down
```

### 2. Scrollback may be empty — only `visible` reads anything

Agents that render on the alternate screen (pi does) write nothing to host scrollback:

```
agent read --source recent            → empty
agent read --source recent-unwrapped  → empty
pane  read --source recent            → empty
agent read --source visible           → works
agent read --source detection         → works, but footer only — no answer text
```

**Default to `--source visible`.** `--lines` then tails the current screen, so the
answer has to fit one screenful. That is the real reason every lane prompt ends with
"keep your final answer under N lines" — anything longer scrolls off and is gone.

### What still works regardless

`agent start`, `wait`, `get`, `read --source visible`, `rename`, `focus`, `attach`, `explain`, `list`, and every `pane` command.

## The loop

```bash
herdr pane send-text "$pane" "<brief>"
herdr pane send-keys "$pane" enter
herdr agent wait <name> --until idle --until done --timeout 600000
herdr agent read <name> --source visible --lines 40
```

Keep the pane ID for the whole life of the lane, not just the name.

## Follow-up and hand-off

The agent stays alive after it answers. Same two commands to continue the conversation; its context carries over.

Hand a lane to the user with:

```bash
herdr agent attach <name>     # or: herdr agent focus <name>
```

Tell them the name when you report. That is the point of naming lanes after what they own.
