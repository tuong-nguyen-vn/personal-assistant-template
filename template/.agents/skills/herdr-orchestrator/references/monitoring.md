# Herdr — monitoring and reporting

Load when a batch is running. Assumes `SKILL.md` is already read.

## Wait, do not poll

```bash
herdr agent wait api --until blocked --until done --timeout 600000
```

Blocks until that agent settles. No `--until` matches `idle`/`done`/`blocked`. No `--timeout` waits forever — always set one.

`agent wait` returns immediately if the state already matches. Reading output in a loop instead of waiting is how you burn context for nothing.

## The three settled states are not equal

| State | Meaning | Do |
|---|---|---|
| `blocked` | Approval or question UI on screen | Read that pane, decide or escalate |
| `done` | Finished background work, tab not yet seen | Read the result, summarize |
| `idle` | Ready for input, tab already seen in UI | Same as done |
| `unknown` | Present, unclassifiable | **Not success.** Read and judge manually |

`done` decays to `idle` once the tab is focused. Reading via CLI does not mark it seen, so the distinction survives your reads.

## Waiting on several lanes — wait-any, not serial

`agent wait` takes a single target. Waiting 1→2→3 in turn is blind to lane 3 if it finishes first — you're blocked on lane 1 and notice lane 3 late.

Use `bin/wait-any` instead. It subscribes to `pane.agent_status_changed` for every lane on one socket connection and prints each lane **as it settles, in finish order** — order-independent, zero polling. It talks to the Herdr socket directly (newline-delimited JSON-RPC); the CLI does not yet expose events as a user command, so the script calls the socket itself.

```bash
# print each lane in finish order, one per line: pane_id<TAB>status<TAB>name
bin/wait-any --timeout-ms 600000 "$pane_api" "$pane_ui" "$pane_review"
```

Each line is a lane settling (idle/done/blocked). Handle them in arrival order: read → verify → summarize the first finisher, then re-run for the rest (or let one call run to collect all of them). Exit 0 = all lanes settled; 124 = timeout with the still-pending panes named on stderr.

`--no-seed` skips lanes already settled at startup — use it when you know every lane is working and want to hear only about live completions.

**Fallback** if `wait-any` is unavailable: serial `agent wait` works, just slower to react:

```bash
for a in api ui review; do
  herdr agent wait "$a" --timeout 600000 >/dev/null || echo "$a: timeout"
  echo "== $a: $(herdr agent get "$a" | jq -r '.result.agent.agent_status')"
done
```

Handle a `blocked` lane as soon as you see it — it is burning wall-clock while others run.

## Reading, cheaply

```bash
herdr agent read api --source visible --lines 40
```

**`--source visible` is the reliable source for agents that render on the alternate screen** (pi does). `recent` and `recent-unwrapped` can return nothing — pi renders on the alternate screen, so its output never enters host scrollback. `detection` works but only shows the footer.

That means `--lines` may tail the *current screen*, not history. An answer longer than one screenful has already scrolled away and cannot be recovered. The fix is upstream: tell each lane how short its answer must be.

## Handling `blocked`

1. Read that pane only.
2. Decide if it is within what the user already approved.
3. In scope → answer it: `herdr pane send-keys "$pane" enter`, or type a reply with `herdr pane send-text "$pane" "<answer>"` then `herdr pane send-keys "$pane" enter`.
4. Out of scope, destructive, or ambiguous → **stop and ask the user**. Never approve a `rm -rf`, a force push, or a schema change on an agent's behalf.

`pane send-keys` takes `esc`, `enter`, `up`, `down`, `ctrl+c`. `agent send-keys` may fail on your setup — always target the pane (see `main-agent-launch.md`).

## Reporting to the user

One table. Never paste transcripts.

```
| Lane   | Model     | State | Result                          | Needs you |
|--------|-----------|-------|---------------------------------|-----------|
| api    | sonnet-5  | done  | 3 endpoints added, tests pass   | –         |
| ui     | sonnet-5  | block | asks to delete legacy component | yes       |
| review | opus-5    | done  | 2 findings, both in api         | –         |
```

Then: what you decided and why, what is still open, one recommended next action. Detail only if asked. Name the lanes — the user can pick one up with `herdr agent attach <name>`.

Verify before reporting. An agent claiming success is a claim, not evidence — check the diff or run the test yourself. Never forward an unverified lane as done. This matters most for cheaper long-horizon lanes: some (GLM-class) have a documented tendency to game a pass/fail signal.

## Cleanup

Close each lane's pane once you have summarized it, then close the batch tab when the last one is done. Dead panes left open shrink every live pane until nothing is readable.

Exceptions: never close a pane whose agent is still `working`, and never close a pane the user opened — ask first. If the user is actively reading a lane, leave it and say so.
