# Customization guide

`ONBOARDING.md` is the agent-driven path; this file is the **human-facing reference** for
every knob you can turn, and for tuning the config after the initial scaffold.

## The placeholders

Every `{{TOKEN}}` in `template/` is a value the config depends on. After scaffolding they
should all be filled. This table is what each one means, so you can change them later.

| Token | File(s) | What it is |
|---|---|---|
| `{{ASSISTANT_NAME}}` | `identity.md`, `AGENTS.md` | The name the assistant calls itself. Also the directory base. |
| `{{ASSISTANT_NAME_SLUG}}` | `INDEX.md`, `AGENTS.md` | Lowercase `[a-z0-9-]` slug, derived from the name. |
| `{{ROLE_LABEL}}` | `identity.md` | One-phrase role. Default `Chief of Staff`. |
| `{{TONE_DESCRIPTION}}` | `identity.md` | One-line tone spec. |
| `{{MODEL_DEFAULTS_SUMMARY}}` | `identity.md` | One-line summary of model routing, surfaced on every session. |
| `{{DESTINATION_PATH}}` | `INDEX.md` | Absolute path to the config dir. |
| `{{SKILLS_LIST}}` | `AGENTS.md` | Markdown bullets naming the installed skills. |
| `{{#USES_HERDR}}…{{/USES_HERDR}}` | `identity.md` | Conditional block — keep iff the Herdr skill is installed. |
| `{{#CODING_COORDINATOR}}…{{/CODING_COORDINATOR}}` | `identity.md`, `AGENTS.md` | Conditional block — keep iff the role is Coding Coordinator (installs `coding/protocol.md`). |
| `{{PROJECT_ROWS}}` / `{{PROJECT_ROW}}` | `INDEX.md` | One table row per tracked project. |

## What you can change, and how

### Rename the assistant

Change `{{ASSISTANT_NAME}}` and `{{ASSISTANT_NAME_SLUG}}` everywhere, and rename the
directory. `grep -r '<old-name>'` to catch stragglers.

### Change the role

Edit `## Mission` in `identity.md`. The default is a coordinator that delegates to other
agents. If you want a hands-on coder, rewrite the mission to match — but then the
"manage other agents" section and the Herdr skill stop making sense; drop them.

### Tune the tone

Edit the `Tone:` line in `identity.md`. Examples that work well:
- `direct, concise, candid. No flattery, no hedging, no preamble.` (default)
- `warm and patient; explain your reasoning when asked; never condescending.`
- `terse and dry; skip pleasantries entirely.`

### Change the language rule

The default replies in the user's language, turn by turn. To force a fixed language,
replace the `## Language` section of `AGENTS.md` (e.g. "Always reply in Vietnamese").

### Add or remove a project

To add: copy `projects/_TEMPLATE/` to `projects/<slug>/`, fill `PROJECT.md` (especially
**Verify** and **Risk areas** — they are how the assistant proves work is done and where
it slows down), and add a row to `projects/INDEX.md`. To remove: delete the directory and
the row.

### Change model routing

If you use the Herdr skill, edit
`.agents/skills/herdr-orchestrator/references/models.config.md` — that one file is the
bridge between the routing logic (in `model-routing.md`) and your actual providers. The
rest of the skill reads from it. See `MODELS.md` for which model fits which task.

### Switch the role (incl. to/from Coding Coordinator)

The role is set at scaffold time from the Q2 preset. To change it later: edit `identity.md`
(`{{ROLE_LABEL}}` becomes the role text) and, if switching to/from Coding Coordinator,
add/remove the `coding/protocol.md` knowledge-file pointer in `AGENTS.md` and the
`{{#CODING_COORDINATOR}}` blocks in `identity.md`. Re-run `./scaffold.sh <dest> --no-coding`
(or without) to drop/install the protocol file cleanly.

## Updating your tools and models

Your setup is not static: you add a CLI, a provider adds a model, a model gets deprecated.
The template treats these as **config edits, not code changes** — re-run an audit, diff
against what is recorded, edit the one right file. No reinstall needed.

### The source of truth is the live machine, not the files

What you wrote into `models.config.md` at scaffold time is a snapshot. To update, **audit
first, edit second**:

```bash
./bin/audit.sh           # prints: installed agent CLIs, providers, models, herdr integrations
                          # diff this against models.config.md to find drift
```
`audit.sh` lives at the repo root (or `bin/audit.sh`). It only reads — it never edits
anything — so you can run it freely any time something feels stale.

### What to edit, by change type

| Change | File to edit | How to verify |
|---|---|---|
| Added/removed an agent CLI (installed `cursor`, dropped `codex`, …) | `MODELS.md` → "Which tool can run which model"; `models.config.md` → Integrations line | `bin/audit.sh` → Agent CLIs section; `herdr integration status` |
| A provider added/removed a model | `models.config.md` → Model → provider/id table | `bin/audit.sh` → Models section |
| Want a different **default** / fallback / top-tier model | `models.config.md` → Defaults block; `identity.md` → `{{MODEL_DEFAULTS_SUMMARY}}` line | start a session, check the assistant states the right default |
| Model got deprecated or renamed | delete its row in `models.config.md`; re-route any lane that used it | `grep` the old id across the config |
| Learned a new strength/failure of a model | `models/catalog.md` (the per-model depth) | — |
| Switched primary agent harness (pi → Claude Code, …) | re-run `ONBOARDING.md` step 1 — identity/AGENTS rules may need adjusting | bootstrap a session in the new harness |

### Keeping `models.config.md` in sync — a checklist

Run this when you add a tool, a provider, or a model:

1. **Audit.** `./bin/audit.sh > /tmp/now.txt` and eyeball it.
2. **Integrations.** Update the "Integrations installed" block from
   `herdr integration status`. This decides which `--kind` flags give trustworthy state.
3. **Providers table.** List every provider key you have. Note for each whether it honors
   `--thinking` — that affects routing.
4. **Model → provider/id.** For each model you can actually run, write the exact
   `--model` string. Delete rows for models you cannot run.
5. **Defaults.** Point `default`, `top-tier`, `fallback`, `investigation`, `images` at
   rows that exist above. If a role has no model, say so (the skill routes around it).
6. **Strip the `<!-- CONFIG -->` banners** you no longer need — once a section is filled,
the banner has done its job.

### Adding an agent CLI you have not used before

1. Confirm it is on PATH: `which <cli>` and `<cli> --version`.
2. Install its Herdr state integration if you want reliable `idle`/`done`/`blocked`:
   `herdr integration install <kind>` (this changes shared state — the onboarding agent
   asks before running it).
3. Record it: add a row in `MODELS.md`'s "Which tool can run which model" and update
   `models.config.md`'s Integrations line.
4. Decide if it earns a lane shape the skill does not already cover. If not, leave it in
   the catalog as an option; you do not have to route any lane to it.

### Tearing down a tool or model

- Remove the row from `models.config.md` first, so no lane routes to it.
- `grep` the config for its id to catch strays.
- Leave it in `MODELS.md`'s catalog if you might reinstall; delete the row if not.
- `herdr integration uninstall <kind>` only if you want Herdr to stop detecting it — this
  is a shared-state change, so confirm first.

### Add another skill

Drop it under `.agents/skills/<name>/SKILL.md`. pi discovers it natively. Add a bullet to
the `## Skills` list in `AGENTS.md`.

## Tuning budgets (advanced)

The tier budgets in `AGENTS.md` (~1500 / ~2500 chars) are deliberate: they keep the
always-loaded files small. If a Tier 1 or Tier 2 file outgrows its budget, **move content
down a tier** (into `notes/`) rather than raising the budget. The budget is on the file
as loaded, not on the project as a whole.

## What not to change

- `AGENTS.md`'s `## Bootstrap` order (identity → INDEX → tier 3 on demand). The order is
  how the progressive-disclosure memory works.
- The `_TEMPLATE/` directory layout. Copies of it are how new project memory entries stay
  consistent.
- The `<!-- CONFIG -->` and `<!-- MACHINE -->` banners in the skill — they tell future
  readers (you or an agent) what is setup-specific vs portable.
