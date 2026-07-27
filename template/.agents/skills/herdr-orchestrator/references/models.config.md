<!-- CONFIG: This is the one file you must edit before the skill is useful.
     Fill in your real providers and model ids, then delete this banner.
     See ../../CONFIG.md for a walkthrough. -->

# Models available on this machine

This file is the bridge between the routing logic in `model-routing.md` (canonical model
ids) and the literal `--model provider/id` string each lane needs. Fill it in once per
setup; the rest of the skill reads from here.

## How to populate it

For each canonical model, find which of your providers carries it and what the exact id
string is. The source of truth on your machine:

```bash
pi --list-models | grep -i <name>     # shows provider/id pairs pi can resolve
pi --list-models <search>             # narrow
herdr integration status              # which agent kinds have state hooks
```

Check the pane footer after `agent start` — it prints the model that actually loaded. A
bare id that resolves to the wrong provider boots into `No API key found for <provider>`.

## Providers

<!-- CONFIG: list your configured providers. Example:
| Provider | Carries | Notes |
|---|---|---|
| `<proxy-or-aggregator>` | claude-opus-5, claude-sonnet-5, glm-5.2, gemini-3.6-flash, … | honors `--thinking` |
| `<vendor-hosted>` | swe-1-7 | ignores `--thinking` (footer reads `off`) |
-->

| Provider | Carries | Notes |
|---|---|---|
| `<provider-a>` | _fill in_ | _e.g. honors `--thinking`_ |
| `<provider-b>` | _fill in_ | _e.g. ignores `--thinking`_ |

## Model → provider/id

<!-- CONFIG: for each canonical model you have access to, write the exact --model string.
     Delete rows for models you do not have. Add rows for anything else you carry. -->

| Canonical model | `--model` value | Ctx | Thinking | Route it to |
|---|---|---|---|---|
| `claude-opus-5` | `<provider>/claude-opus-5` | 1M | yes | Reserved — see `model-routing.md` gate |
| `claude-sonnet-5` | `<provider>/claude-sonnet-5` | 1M | yes | **Default for everything** |
| `glm-5.2` | `<provider>/glm-5.2` | 1M | yes | Long grind; fallback when default is out of quota |
| `swe-1-7` | `<provider>/swe-1-7` | 262K | ignored | Exhaustive codebase exploration, test writing |
| `gemini-3.6-flash` | `<provider>/gemini-3.6-flash` | ~1M | yes | Image analysis, cross-family review — not implementation |

## Defaults used by the rest of the skill

<!-- CONFIG: these are referenced from batch.md and model-routing.md.
     Point them at the --model values you filled in above. -->

- **Default (most lanes)**: `<provider>/claude-sonnet-5`
- **Top-tier (gated)**: `<provider>/claude-opus-5`
- **Fallback when default is out of quota**: `<provider>/glm-5.2`
- **Investigation / read-only**: `<provider>/swe-1-7`
- **Image analysis**: `<provider>/gemini-3.6-flash`

## Integrations installed

<!-- CONFIG: from `herdr integration status`. Determines which `--kind` flags
     produce trustworthy lifecycle state. -->

- Installed: _e.g. `pi`_
- Not installed (falls back to screen detection → more `unknown`): _e.g. `claude`, `codex`, `gemini`, …_

Use `--kind <installed>` for any lane whose state you want to `wait` on reliably.
