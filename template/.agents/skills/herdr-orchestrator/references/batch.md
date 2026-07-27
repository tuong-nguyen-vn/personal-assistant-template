# Herdr — planning a batch

Load when splitting work across agents. Assumes `SKILL.md` is already read.

## How many agents

| Count | When |
|---|---|
| 1 | Sequential work, or anything touching one area of the codebase. |
| 2 | Implementation + review, or two independent investigation angles. |
| 3 | Default ceiling for genuinely independent lanes. |
| >3 | Only when scopes are provably disjoint and the coordination cost is worth it. |

Parallelism is not free: every agent costs a prompt, a wait, a read, and a merge. Two agents on overlapping files are slower than one, because you pay for the conflict too.

## Ownership is the only rule that matters

Each lane owns a set of files. **No two lanes write the same file.** State the boundary inside the prompt, not just in your head:

> You own `src/api/**`. Do not edit anything outside it. If a fix is needed elsewhere, report it instead of making it.

Investigation lanes (read-only) can overlap freely — they write nothing. Say "do not edit files" explicitly for those.

## Isolation: same tree or worktree

Same working tree is fine when lanes own disjoint paths and none of them run `git` write commands.

Use a worktree when lanes need to commit, switch branches, or run a full build that writes artifacts:

```bash
herdr worktree create --cwd ~/projects/app --branch lane-api --base main --no-focus --json
```

Returns its own workspace and root pane. Cost: separate checkout, separate install, slower start. Do not reach for it by default.

## Layout

**One tab per batch, always.** Never split into the tab where you are talking to the user — a batch beside their session squeezes every pane down to a few unreadable lines. The batch tab is also what you close at the end, in one move.

The tab's root pane is a usable lane. Split from it and capture each returned ID:

```bash
base=$(herdr tab create --cwd ~/projects/app --label batch --no-focus | jq -r '.result.root_pane.pane_id')
p2=$(herdr pane split "$base" --direction right --no-focus | jq -r '.result.pane.pane_id')
p3=$(herdr pane split "$base" --direction down  --no-focus | jq -r '.result.pane.pane_id')
```

Never predict a pane ID. `pane move` changes it, and a wait already running against the old ID dies with `agent_not_running`.

Three lanes is already a cramped tab. Past that, use a separate workspace per group rather than slicing one tab thinner.

## Naming

Names match `[a-z][a-z0-9_-]{0,31}`, must be unique among live agents, and are released when the agent exits. Name lanes after what they own (`api`, `ui`, `review`), not after the model — it keeps the report readable and gives the user something to `herdr agent attach`.

Pass the same name to the agent as `-n <name>` so the pane title reads the agent name + project.

## Assigning models

Each lane is a main agent with its own model. Match the model to what the lane actually needs — see `model-routing.md`, and use the `provider/id` strings from `models.config.md`.
Defaults that hold most of the time:

| Lane | Model (canonical) |
|---|---|
| implement, spec'd | your default (e.g. claude-sonnet-5) |
| review | your default, or swe-1-7 |
| investigate, read-only | swe-1-7 |
| long grind, spec settled | glm-5.2 |
| ambiguous, needs a decision | claude-opus-5 |

**Default is the default.** The top tier only when the lane clears the gate in `model-routing.md` — ambiguity, architecture, high-risk irreversible change, or the default already failed. One at most per batch, and never as the routine reviewer.

**Default out of quota → fall back to your cheaper long-horizon model**, not up to the top tier. Verify anything that lane reports as passing, and say in your report which lanes ran on the fallback.

## Prompt shape

Every prompt must stand alone — the agent shares no context with you:

1. Goal, one sentence.
2. Ownership boundary — the exact paths it may write.
3. What "done" looks like.
4. "Keep your final answer under N lines." — this is a context control, not politeness.

Tune for the model: hard boundaries for `swe-1-7` (it expands scope), no "double-check your work" for `claude-opus-5` (it already does, and the instruction makes it over-verify), independent verification of anything the cheaper long-horizon model reports as passing.

Send it with `pane send-text` + `pane send-keys enter` — the pane commands work for everyone; `agent prompt` may not (see `main-agent-launch.md`). Point 4 is not politeness: reads may only see the current screen, so an answer longer than one screenful is unrecoverable.

## Closing the batch

Summarize each lane as it settles, then close its pane. When the last one is summarized, close the tab. Do not leave finished panes sitting there while you open new ones.
