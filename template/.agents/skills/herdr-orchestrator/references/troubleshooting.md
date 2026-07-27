# Herdr troubleshooting

Load only when something behaves wrong.

## `agent_not_ready: no longer the pane foreground process`

`agent prompt` or `agent send-keys` against an agent whose binary on PATH is a *launcher*
that spawns the real CLI as a child (e.g. the AMP-Pi launcher `@aaroncql/pim-agent`).
Expected on such setups, not a fault: the foreground group holds two processes.
Confirm with `herdr pane process-info --pane <id>`.

Use `pane send-text` + `pane send-keys` instead. See `main-agent-launch.md`.

## Agent boots into `No API key found for <provider>`

You passed a bare `--model <id>`. The agent resolved it to a provider that is not configured. Always `--model provider/id`; `<agent> --list-models <search>` shows which providers carry that id. Kill the pane and relaunch — do not try to fix it with `/login`.

## Footer shows `off` thinking despite `--thinking high`

The model is on a provider that ignores the thinking level. If the lane needs deep reasoning, route it to a provider/model that honors thinking instead. See `models.config.md` for which of your providers honor it.

## `Pim requires the Bun runtime`

You launched the real pi binary directly to dodge a launcher. Its extensions need Bun. Go back to `herdr agent start --kind pi`.

## `agent_prompt_stalled`

`agent prompt --wait` starting from a non-working state requires an observed lifecycle change within 5000ms. No change → this error.

Check `herdr agent get <target>`, read the screen with `--source visible --lines 20`, and clear a stuck modal with `pane send-keys <id> esc` before retrying.

A caller `--timeout` of ≤5000 returns a plain `timeout` instead of this error.

## `agent_not_running`

The alias no longer resolves. Causes: the agent exited, was replaced, was released, or the pane was moved (which changes its workspace-qualified ID).

Re-resolve from scratch: `herdr agent list | jq -r '.result.agents[] | "\(.pane_id) \(.agent) \(.agent_status)"'`. After a `pane move`, use `.result.move_result.pane.pane_id`.

## Reads come back empty or truncated

`--source recent` and `recent-unwrapped` can return **nothing at all** for agents that
render in the **alternate screen** (pi does). Not a bug to work around — those rows never
enter Herdr's host scrollback. `pane read --source recent` can be empty for the same
reason.

`--source visible` works. `detection` works but shows only the footer.

Since `visible` is a snapshot of the current screen, an answer that has scrolled past is gone. In order of preference:

1. `--source visible --lines 40`, raising it up to a screenful.
2. Ask for shorter answers next time — the real fix, and why every lane prompt caps its answer length.
3. Enlarge the pane or shrink the font. Bigger fonts and smaller panes make this worse.
4. Last resort: ask the agent to write its full answer to a Markdown file in a temp dir and reply with only the path, then read the file. Do **not** put this in the initial prompt; it is a recovery move.

## State is wrong or stuck on `unknown`

`herdr agent explain <target> --json` shows why Herdr classified it that way.

Most common cause: the agent kind has no state integration, so detection falls back to reading the screen. `herdr integration status` confirms. Use an installed kind for lanes whose state you want to `wait` on reliably; uninstalled kinds sit in `unknown` more often.

`unknown` never means success. Read the pane and judge for yourself before reporting anything.

## Waits that never return

No `--timeout` means indefinite, by design. If a wait is hanging, you omitted it.

Also check: `agent wait` without `--until` matches only `idle`/`done`/`blocked`. An agent stuck in `working` or sitting at `unknown` matches none of those. Add `--until unknown` when that is a real outcome.

## `done` vs `idle` confusion

Same underlying state. `done` means background work finished and that tab has not been seen in the focused UI yet; it becomes `idle` once the tab is focused, or `pane focus`/`agent focus` targets it. Reading through the CLI does **not** mark it seen, so your reads do not destroy the distinction. Use exact `--until` when it matters.

## `agent start` fails

The pane must be at its interactive shell prompt — no editor, no foreground command, no other agent. Check with `herdr pane process-info --pane <id>`. Return the pane to its prompt (`pane send-keys <id> ctrl+c` if you own it) and retry.

Also verify the executable for that `--kind` is actually on PATH. `agent start` only succeeds once Herdr detects the expected agent in the same terminal.

## Protocol or version mismatch

`herdr status` reports client and server. If they disagree, the binary was updated while a server kept running. `herdr server reload-config` picks up config changes only; a version mismatch needs a server restart, which kills running panes — **ask the user, never do it mid-batch**.

## Nothing works at all

Confirm the basics before debugging deeper:

```bash
echo "$HERDR_ENV" "$HERDR_PANE_ID"; herdr status
```

Empty `HERDR_ENV` → you are not in a Herdr pane and must stop. Socket errors with `HERDR_ENV=1` set → the server died; that is the user's to restart.
