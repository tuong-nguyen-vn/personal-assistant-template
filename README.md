# Personal Assistant Template

A template for bootstrapping a **personal coordinator agent** — an assistant with its
own identity, operating rules, project memory, and (optionally) a Herdr-orchestration
skill for delegating to other agents. The reference instance is "Mina"; this repo
scaffolds one like it for a new user.

> **You are an agent reading this.** Your job right now is to onboard a user: read the
> template, interview them, copy `template/` to a destination, and fill in the
> placeholders with their answers. The walkthrough is in
> [`ONBOARDING.md`](./ONBOARDING.md). Read that next — it is written for you.

## What's in the box

```
personal-assistant-template/
├── README.md                 # this file — start here
├── ONBOARDING.md             # the agent-driven interview script (read this next)
├── CONFIG.md                 # human-facing customization guide (deep config)
├── MODELS.md                 # catalog: agent CLIs, their models, task-fit (browse to pick)
├── scaffold.sh               # one-shot copy: template/ → <destination>/
├── bin/audit.sh              # read-only: what CLIs/models this machine actually has
└── template/                 # the files that become the user's config
    ├── identity.md           #   who the assistant is
    ├── AGENTS.md             #   operating rules
    ├── models/catalog.md     #   per-model knowledge (shared, on-demand)
    ├── coding/protocol.md    #   coding coordination protocol (preset, on-demand)
    ├── projects/
    │   ├── INDEX.md          #   project map (tier 1)
    │   └── _TEMPLATE/        #   copy this per project
    └── .agents/skills/
        └── herdr-orchestrator/   # the Herdr delegation skill (optional)
```

## Two ways to use this

1. **Agent-driven (recommended).** Point your agent at this repo. It reads
   `ONBOARDING.md`, interviews you, and builds the config. You answer questions; it
   does the work.
2. **Manual.** Copy `template/` to a destination yourself, then follow `CONFIG.md` to
   fill in the placeholders by hand.

## Requirements (check before starting)

- A terminal agent harness that reads `AGENTS.md` at session start (pi / AMP-Pi,
  Claude Code, and similar). The template assumes this convention.
- `jq` for the skill's JSON parsing.
- **For the Herdr skill only:** the [Herdr](https://herdr.dev) terminal workspace
  manager. If the user does not use Herdr, the skill is skipped — the rest of the
  config still works as a project-memory + identity layer.

## What the user ends up with

A directory (default `~/projects/<assistant-slug>/`) containing:

- `identity.md` — their assistant, named what they chose, with the role and tone they picked.
- `AGENTS.md` — operating rules (progressive-disclosure project memory).
- `projects/INDEX.md` — seeded with their real projects.
- `.agents/skills/herdr-orchestrator/` — installed only if they use Herdr, with
  `models.config.md` filled in for their actual providers/models.

After that, they open a session in that directory and the assistant is live.

## Next

- Agent → read [`ONBOARDING.md`](./ONBOARDING.md).
- Human → read [`CONFIG.md`](./CONFIG.md) for the full list of placeholders and how to tune them, and [`MODELS.md`](./MODELS.md) for the model/tool catalog.
