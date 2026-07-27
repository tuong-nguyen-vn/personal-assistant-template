# Models, tools, and task-fit

This catalog helps you fill `models.config.md` and pick the right model per lane. Three
layers, often confused — keep them apart:

- **Tool** — the agent CLI you run in a pane (pi, Claude Code, Codex, …). The tool
  determines the harness features (session handling, skills, approval UI).
- **Provider** — the pipe that holds your API key and exposes model ids
  (`anthropic`, `openai`, `google`, a self-hosted proxy, a vendor portal, …). The same
  model can sit behind several providers.
- **Model** — the thing that thinks (`claude-sonnet-5`, `glm-5.2`, …). The model, not the
  tool or the provider, determines task-fit.

You pick a **tool** for the harness, a **provider** because it has your key, and a
**model** for the lane. `--model provider/id` is how all three meet.

## Agent CLIs (pick yours)

Each entry below is one CLI you might run inside a Herdr pane: what it is, which models
it can run, and what each model is for. **Browse this, then tell the onboarding agent
which CLIs you use** — it configs the rest from your answers. Nothing here is
pre-configured: you pick, the agent fills in `models.config.md`.

Deep per-model analysis (strengths, failure modes, prompt shapes) lives in
`template/models/catalog.md`; the one-liners here are for *choosing*, not for routing.

Only some CLIs will have Herdr state integrations on your machine — `herdr integration
status` says which. Installed kinds give reliable `idle`/`done`/`blocked`; others fall
back to screen detection and sit in `unknown` more often.

### pi / AMP-Pi  —  `--kind pi`

**What it is**: the reference CLI for this template. Reads `AGENTS.md`, discovers
`.agents/skills/`, full session model, thinking levels.

**Model source**: aggregator — runs **any model your configured providers carry**. The
most flexible CLI; reaches every family below through one harness.

**Models** (whatever your providers expose — check `pi --list-models`):
- `claude-opus-5` — top-tier judgment: ambiguous specs, architecture, irreversible changes
- `claude-sonnet-5` — the default worker: multi-step coding, brownfield, debugging
- `glm-5.2` — long-horizon grind on a settled spec; the fallback when Sonnet is out of quota
- `gemini-3.6-flash` — image analysis, cross-family review (never implementation)
- `swe-1-7` — exhaustive codebase exploration, test writing, edge-case hunting
- `gpt-5.x`, `grok-4.x`, … — whatever else your providers carry

**Distinct edge**: the only CLI that routes a lane to *any* model — the universal lane
runner, and the Herdr skill's default.
**Watch for**: the AMP-Pi launcher wraps pi as a child → agent-targeted input may break;
use `pane send-text`.

### Claude Code  —  `--kind claude`

**What it is**: Anthropic's CLI. Strong coding defaults, approval UI for destructive ops.

**Model source**: **Anthropic only.**

**Models**:
- `claude-opus-5` — top-tier: judgment, architecture, ambiguous specs, irreversible changes
- `claude-sonnet-5` — the default worker: multi-step coding, brownfield, debugging
- older Claude entries (Sonnet 4.x, Opus 4.x) — fallback only

**Distinct edge**: approval UI and sandboxing; the harness to pick when the task is
Claude-shaped and you want its particular approvals.
**Watch for**: does not read `AGENTS.md` / `.agents/skills/` the way pi does, so the
identity and skill layers do not load. State integration may be uninstalled.

### Devin CLI  —  `--kind devin`

**What it is**: Cognition's CLI; host of the SWE-1.x family.

**Model source**: **Cognition only.**

**Models**:
- `swe-1-7` — exhaustive codebase exploration, multilingual repos, test writing,
  edge-case hunting. Probes edge cases and writes throwaway scripts to settle semantics.

**Distinct edge**: explores a codebase more thoroughly than any other model here —
measurably more tool calls, file reads, greps per run.
**Watch for**: smallest context (262K), no thinking control, and **scope creep is
documented by its own makers** — a hard ownership boundary in the prompt is mandatory.

### OpenCode  —  `--kind opencode`

**What it is**: open-source multi-provider CLI (sst/opencode). Same flexibility as pi.

**Model source**: **any provider you configure.**

**Models**: whatever your providers carry — same reach as pi if you point it at the same
keys (Claude, GLM, Gemini, SWE via a fronting provider, GPT, …).

**Distinct edge**: open-source and hackable; pick it as your universal runner if you
prefer it to pi.
**Watch for**: Herdr state integration varies — confirm with `herdr integration status`.

### Codex  —  `--kind codex`

**What it is**: OpenAI's CLI.

**Model source**: **OpenAI only.**

**Models**:
- `gpt-5.x` family (e.g. `gpt-5.6-sol`, codex-specialized variants) — general coding,
  reasoning, OpenAI-stack repos

**Distinct edge**: when you want GPT-5.x inside its own harness, or a model pi can't reach.
**Watch for**: no `AGENTS.md` bootstrap.

### Gemini CLI  —  `--kind gemini`

**What it is**: Google's CLI. Native image input, long context.

**Model source**: **Google only.**

**Models**:
- `gemini-3.6-flash` — image analysis, cross-family second-opinion review, light discovery
- `gemini-3.x-pro` variants — heavier reasoning, when available

**Distinct edge**: native image handling; the image lane. Also a cross-family reviewer
(different family than Claude).
**Watch for**: **never implementation** — policy. Route image/analysis here, not coding.

### Cursor  —  `--kind cursor`

**What it is**: IDE-integrated agent. Multi-model via Cursor's own service.
**Model source**: Cursor's menu (Claude / GPT / Gemini options it exposes).
**Distinct edge**: IDE-paired work. Not a clean headless lane runner.

### Copilot  —  `--kind copilot`

**What it is**: GitHub's agent. Multi-model menu.
**Model source**: Copilot's menu (Claude / GPT / Gemini options it exposes).
**Distinct edge**: when you already live in the Copilot ecosystem.

### Others  —  `cline`, `amp`, `grok`, `kimi`, `kilo`, `qodercli`, `maki`, …

Open-source or vendor CLIs. Usually multi-provider (any keys you supply), as flexible as
pi, but Herdr state integration varies — expect more `unknown` states until you install
the integration.

### How to choose

- **Pick as your primary lane runner whichever aggregator CLI you are used to** — pi,
  AMP-Pi, OpenCode, aider, … any of them reaches every model your providers carry. There
  is no built-in default; it is whichever one you already run.
- Reach for a vendor-locked CLI **only when it has a feature the aggregator lacks**:
  Claude Code's approvals, Gemini CLI's native image handling, Devin's SWE harness, or a
  model only that CLI carries.
- A model id is not always reachable from every tool — `claude-*` need an Anthropic route,
  `swe-1-7` needs Devin or a provider that front-ends it. If a routing decision needs a
  model the chosen tool can't carry, switch the `--kind`, not just the `--model`.


## Providers (the `provider/` prefix)

A provider is just the API route. Common shapes:

- **First-party** — `anthropic`, `openai`, `google`. One model family each, official
  pricing.
- **Aggregator / proxy** — a single key that fronts many model families (OpenRouter,
  a self-hosted proxy, a vendor portal). Often where you get non-first-party models
  (e.g. Devin's SWE models, or GLM through a proxy).
- **Hosted harness** — `devin`, etc. Models that only exist inside that harness.

The model id alone does **not** pick the provider. `glm-5.2` may exist on two providers
with different limits and thinking support. **Always pass `provider/id`** and record the
exact string in `models.config.md`.

To see what your setup actually carries:
```bash
pi --list-models | sort -u
pi --list-models <name>     # narrow
herdr integration status    # reliable --kinds
```

## Models (the `id`), by task-fit

Per-model strengths and failure modes live in `template/models/catalog.md` — a shared,
on-demand reference kept **outside** the Herdr skill (a user with no Herdr still needs
it to pick models for any tool). This is the short table for quick routing.

| Task | Best pick (canonical) | Acceptable | Avoid |
|---|---|---|---|
| Spec'd implementation, brownfield fix | `claude-sonnet-5` | `glm-5.2` (verify output) | image models |
| Many small independent edits | `claude-sonnet-5` | `claude-opus-5` (overkill) | — |
| Code review, bug-finding | `claude-sonnet-5` (high thinking) | `swe-1-7` (reads more) | cheap-tier alone |
| Long grind, spec already settled | `glm-5.2` | `claude-sonnet-5` | top-tier (waste) |
| "How does this work / where is X used" | `swe-1-7` | `claude-sonnet-5` | image models |
| Test writing, edge-case hunting | `swe-1-7` | `claude-sonnet-5` | — |
| Image analysis (charts, screenshots) | `gemini-3.6-flash` | (anything with vision) | non-vision models |
| Ambiguous spec, a decision must be made | `claude-opus-5` | `claude-sonnet-5` | cheap-tier |
| Architecture, high-risk irreversible change | `claude-opus-5` | — | anything weaker |

### Rules of thumb

- **Default to Sonnet 5** (or your strongest generalist). Route up only with a reason.
- **Out of quota → cheaper long-horizon**, never an automatic upgrade to the top tier.
- **Pair implementer + reviewer from different families** — they catch different things.
  `swe-1-7` reviewing Sonnet's work is cheap and thorough.
- **Never trust a pass/fail signal from the cheap tier alone** — verify the diff yourself.
- **Image analysis → image-capable model, never a coding model.**
- **Never route two lanes to the same model *and* the same kind of work** — you pay twice
  for one answer.

## If you do not have the canonical set

The routing *logic* in `model-routing.md` is stable even if your model names differ.
Map your models onto these **roles**, then write the role→model line into
`models.config.md`:

| Role | What it must be good at | Typical model |
|---|---|---|
| **default** | Multi-step coding, debugging, brownfield. | strongest generalist coder you have |
| **top-tier** (gated) | Judgment, ambiguous specs, architecture, irreversible changes. | your SOTA, expensive one |
| **fallback** | Long-horizon grind when the default is out of quota. | cheaper long-context coder |
| **investigation** | Reads a whole codebase, writes throwaway probes. | high-tool-call explorer |
| **images** | Read charts/screenshots/diagrams. | any vision-capable model |

If a role has no model in your setup, leave it blank in `models.config.md` and the skill
will route around it (e.g. no image model → no image lane).
