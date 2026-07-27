# AGENTS.md

## Bootstrap (required, before anything else)

At the start of **every** session, before answering or running any other tool:

1. Read `identity.md` — your identity and mission.
2. Read `projects/INDEX.md` — the projects you manage.

Stop there. Do not read any `PROJECT.md` or note file until a project is actually in play. If either file cannot be read, say so explicitly instead of guessing.

## Project memory (progressive disclosure)

Three tiers. Load a tier only when you need it.

| Tier | File | When to load | Budget |
|------|------|--------------|--------|
| 1 | `projects/INDEX.md` | every session | ~1500 chars |
| 2 | `projects/<slug>/PROJECT.md` | when a project comes into play | ~2500 chars |
| 3 | `projects/<slug>/{DECISIONS,KNOWLEDGE}.md`, `notes/*.md` | only when the task needs that topic | no limit |

Route Tier 3 by what is being asked:

- "why is it built this way" → `DECISIONS.md`
- "what does this term / rule mean" → `KNOWLEDGE.md`
- anything else → the `notes/` file `PROJECT.md` points at

Rules:

- Never skip a tier. Index → PROJECT.md → Tier 3, in order.
- Tier 2 before touching a project's code. It holds the commands, constraints, and current blockers.
- Tier 3 is opt-in. Load a file when the task needs it, not "just in case".
- The project's own `AGENTS.md` (in its repo) wins over anything here.

## Writing to project memory

After finishing work that changes durable project knowledge, update this layer in the same turn.

- New project → add a row to `projects/INDEX.md`, then copy `projects/_TEMPLATE/` to `projects/<slug>/`.
- Learned a command or constraint → update Tier 2 and bump `Updated`.
- Made a real decision, or rejected an option for a reason → prepend an entry to `DECISIONS.md`. Never rewrite an old entry; supersede it with a new one.
- Learned a domain term or business rule → `KNOWLEDGE.md`.
- Tier 2 section over budget or past ~15 lines → move it to `notes/<topic>.md`, leave a one-line pointer.
- Something affects several projects → `## Open across projects` in the index.

Do not log sessions here, do not record what the code already says, do not store secrets.

## Skills

Operational how-to lives in `.agents/skills/<name>/SKILL.md`, not in project memory. Project memory holds facts about a project; a skill holds a procedure you execute.

`.agents/skills/` is canonical and pi discovers it natively — no symlink needed. Skills use the same progressive disclosure: `SKILL.md` is the whole workflow, `references/*.md` load only when the task reaches that step.

{{SKILLS_LIST}}

## Knowledge files

- `models/catalog.md` — per-model strengths, failure modes, prompt shapes. Load when picking a model, for any tool — not only Herdr.
{{#CODING_COORDINATOR}}- `coding/protocol.md` — verification, codebase orientation, lane splitting, git safety. Load when coordinating coding agents or touching code.
{{/CODING_COORDINATOR}}

## Language

Reply in the language the user writes in. User writes Vietnamese → reply in Vietnamese. Code, identifiers, and commit messages stay in English.

## Layout

```
{{ASSISTANT_NAME_SLUG}}/
├── AGENTS.md                       # this file — operating rules
├── identity.md                     # who you are                      [tier 0]
├── models/catalog.md             # per-model knowledge — load on demand
{{#CODING_COORDINATOR}}├── coding/protocol.md           # coding coordination protocol — load on demand
{{/CODING_COORDINATOR}}├── .agents/skills/<name>/          # procedures — discovered by pi natively
│   ├── SKILL.md                    #   workflow + guardrails
│   └── references/*.md             #   detail, on demand
└── projects/
    ├── INDEX.md                    # all projects, one row each       [tier 1]
    ├── _TEMPLATE/                  # copy this for a new project
    └── <slug>/
        ├── PROJECT.md              # how to work here + blockers      [tier 2]
        ├── DECISIONS.md            # what was decided, and why        [tier 3]
        ├── KNOWLEDGE.md            # domain and business rules        [tier 3]
        └── notes/*.md              # everything else, on demand       [tier 3]
```
