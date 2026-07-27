# Model routing

Load when deciding which model a lane gets. One question: what does this lane actually need?

> This file is routing **logic**: the gate, the default rule, the fallback rule, the
> pairing rules. Two other files complete the picture:
> - `references/models.config.md` — the `provider/id` strings your setup actually carries.
> - `../../../models/catalog.md` — the per-model strengths, failure modes, and prompt
>   shapes. Load it when you need to reason about a specific model. It lives outside the
>   skill because it is general model knowledge, not Herdr-specific.

## The routing gate

**Default to your strongest generalist coding model** (most setups: Claude Sonnet 5).
Reserve the top-tier model (most setups: Claude Opus 5) for lanes that clear a gate.
Fall back to a cheaper long-horizon model when the default is out of quota — never an
automatic upgrade to the top tier.

The names below are canonical model ids. Prefix with the provider your
`models.config.md` lists for each.

## When the top-tier model is allowed

The top-tier model is not a "better default you reach for when it matters" — it is the
exception, and most lanes do not qualify. Route to it only when at least one of these
is true:

- The spec is genuinely ambiguous and someone has to **decide**, not execute.
- Architecture or a design tradeoff is the deliverable.
- The default already tried and got it wrong, or produced something you do not trust.
- The change is high-risk and irreversible (migration, data, auth, money).
- A novel problem with no established pattern to follow.

If you cannot name which of those applies, use the default. Never more than one
top-tier lane in a batch, and never as the routine reviewer.

## When the default is out of quota

Fall back to your designated **cheaper long-horizon model** (often a GLM-class model),
not to the top tier. Running out of the default model is not one of the gates above.

How you know: the lane's pane shows a rate-limit or quota error instead of an answer,
and `agent get` reports `idle` with nothing produced. Read the pane before assuming —
a slow lane is not an exhausted one.

What changes when you fall back:

- **Verify its output yourself.** Some cheaper models game pass/fail signals
  (see `models/catalog.md`). A green test from this lane is a claim, not evidence.
- **Keep the spec settled.** These models are weakest where the default is strongest:
  ambiguity, and building from a prose description.
- **Use the highest thinking level available** if the provider supports it.
- Tell the user in your report which lanes ran on the fallback and why.

If the lane genuinely needs default-level judgment on brownfield code and the fallback
is not good enough, stop and ask the user rather than silently escalating to the top tier.

## Quick model recap

One line each — load `models/catalog.md` for the full strengths, failure modes, and prompt shapes.

| Model (canonical) | One-liner |
|---|---|
| `claude-opus-5` | Top-tier, gated. Judgment, architecture, irreversible changes. **Verbose, expands scope** — constrain it. |
| `claude-sonnet-5` | **Default.** Brownfield, debugging, multi-step coding. Higher misaligned-behavior rate than Opus — watch destructive ops. |
| `glm-5.2` | Cheaper long-horizon; fallback when default is out of quota. **Reward-hacks** — never trust a green test from it. |
| `swe-1-7` | Explores codebases exhaustively, writes throwaway probes. **Scope creep** — hard ownership boundary mandatory. |
| `gemini-3.6-flash` | Image analysis, cross-family review. **Never implementation** — policy. |

## Picking a lane

Replace the model column with whatever you actually have. The *shape* of the routing
is what is stable.

| The lane is | Model (canonical) | Thinking |
|---|---|---|
| Spec'd implementation, brownfield fix | claude-sonnet-5 | medium / high |
| Many small independent edits | claude-sonnet-5 | medium |
| Code review, bug-finding | claude-sonnet-5 | high |
| Long grind, spec already settled | glm-5.2 | high |
| "How does this work / where is this used" | swe-1-7 | — |
| Test writing, edge-case hunting | swe-1-7 | — |
| Image analysis (charts, diagrams, screenshots) | gemini-3.6-flash | — |
| Ambiguous, a decision has to be made | claude-opus-5 | high / xhigh |
| Architecture, or the default already failed here | claude-opus-5 | xhigh |

Rules of thumb:
- **Default to your strongest generalist.** The top tier needs a reason you can name, from the gate above.
- **Default exhausted → designated cheaper long-horizon model**, never an automatic upgrade to the top tier.
- Never route two lanes to the same model *and* the same kind of work — you pay twice for one answer.
- Pair an implementer with a reviewer from a different family. `swe-1-7` reviewing Sonnet's work is cheaper than the top tier and catches different things, because it actually reads the whole codebase.
- Anything whose success signal is a passing test: do not let the cheaper long-horizon model be the only witness.
- **Image analysis → designated image lane** (often gemini-3.6-flash). Also a cross-family reviewer option (cheaper, different family). **Never implementation.**
