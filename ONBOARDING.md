# Onboarding script (for the agent)

> **You are the agent.** The user pointed you at this repo. Your job: interview them,
> then build a personal-assistant config from `template/`. Work through the steps below
> in order. Do not skip the interview and guess — every placeholder exists because it
> changes the result.

You are building **one directory** that will become the user's assistant. When you are
done, the user opens a session there and the assistant is live under the name they chose.

## How to run the interview

Ask the questions below **in batches**, not all at once. Group A first; once you have the
name and role, you can already start scaffolding while you ask Group B. Keep each turn
short. If the user's answer is ambiguous, ask one focused follow-up — do not spiral.

Record every answer. You will substitute them into the placeholders in `template/`.

When the user says something is fine ("default is ok", "you pick"), use the suggested
default listed with the question.

---

## Step 1 — Interview

### Group A: Identity

1. **Name.** What do you want to call your assistant? One word is best (the reference
   example is "Mina"). This becomes the name it calls itself and the directory name.
   - Default if they decline: `Assistant`.
   - Also derive the **slug**: lowercase, `[a-z0-9-]`, no spaces (e.g. "Mina" → `mina`).

2. **Role.** What is the assistant's job, in one phrase? Offer **presets** — pick one
   or let them describe their own:
   - `Chief of Staff` (default) — generic coordinator across projects.
   - `Coding Coordinator` — controls coding agents across projects; sharpens verification,
     lane splitting, and git safety. Sets `CODING_COORDINATOR=true` and installs
     `coding/protocol.md`. Show them `MODELS.md` and `coding/protocol.md` if they want
     detail. **Best fit if their main use is delegating code work.**
   - `Research Lead`, `Reviewer`, `Project Manager` — other common shapes.
   - Custom — their own one-phrase description.
   - Record the preset (or custom text) as `ROLE_LABEL`, and `CODING_COORDINATOR=true`
     iff they picked the coding preset.

3. **Tone.** How should it talk?
   - Default: `direct, concise, candid. No flattery, no hedging, no preamble.`
   - If they want warmer, sillier, more formal, etc., capture it as a one-line
     description.

4. **Language.** What language should it reply in?
   - Default: `the language the user writes in` (matches the user turn-by-turn).
   - If they want a fixed language, record it.

### Group B: Setup

5. **Which agent CLIs do you use?** This is the core choice — everything else config
   from it. **Show them `MODELS.md` → "Agent CLIs" so they can browse** what each CLI
   is, which models it runs, and what each model is for. Then ask:
   - "Which of these do you already use?" (pi / AMP-Pi, Claude Code, Devin, OpenCode,
     Codex, Gemini CLI, Cursor, Copilot, others)
   - For each one they name, note it; you will record reachable models per CLI in Q7.
   - The template assumes the `AGENTS.md` + `.agents/skills/` convention is read by at
     least **one** of their CLIs (pi/AMP-Pi and OpenCode do). If none of their tools reads
     it, flag it and stop — the identity/skill layers will not load. The other CLIs can
     still run as lanes driven from that primary one.
   - Record the list as `USER_CLIS`.

6. **Do you use Herdr** (the terminal workspace manager) to run multiple agents?
   - **Yes** → install the `herdr-orchestrator` skill. Continue to Q7–Q8.
   - **No / not sure** → skip the skill entirely. Set `USES_HERDR=false`. Skip to Step 2.
     (The per-CLI model knowledge in `MODELS.md` + `models/catalog.md` is still useful to
     them for picking models inside whichever CLI they run — point that out.)

7. **Models, per CLI they chose.** For each CLI in `USER_CLIS`, work out which models it
   can run and which they actually want. **You help them config — do not pre-config.**
   - For each CLI, enumerate the models it can reach **using that CLI's own mechanism**.
     Do not assume any single CLI is the default — the user picked what they are used to.
     - Aggregator CLIs (`pi`, AMP-Pi, OpenCode, aider, …): run that CLI's model listing,
       e.g. `pi --list-models` / `amp-pi --list-models` / `opencode ...` — it spans every
       provider key they have configured.
     - Vendor-locked CLIs (Claude Code, Codex, Gemini CLI, Devin, Cursor, Copilot, …):
       each exposes its model menu differently — `<cli> --help`, an in-app `/model`
       picker, or a config file. Ask the user to open that menu and read the ids off.
   - Cross-check what Herdr can read state from, so you know which `--kind` flags give
     reliable lifecycle:
     ```bash
     herdr integration status
     ```
   - You need enough to fill `models.config.md`: a **default** model, a **top-tier**
     (gated) model if any, a **fallback**, and any specialty models (investigation,
     images) — but only ones reachable from at least one of the CLIs they picked.
   - Default routing suggestion if they have the common set: default = `claude-sonnet-5`,
     top-tier = `claude-opus-5`, fallback = `glm-5.2`, investigation = `swe-1-7`,
     images = `gemini-3.6-flash`. Confirm each is reachable from at least one of their
     chosen CLIs before writing it. See `MODELS.md` and `models/catalog.md` for fit.

8. **Are any of their CLIs launcher/wrapper binaries?** This is a property of *a CLI the
   user picked*, not of any one tool. A launcher spawns the real CLI as a child process
   (AMP-Pi does this to pi; other wrappers exist for other CLIs and have the same
   effect). It decides whether agent-targeted input works for that `--kind`.
   - For each CLI they will run as a lane, check what is actually in its pane:
     ```bash
     herdr pane process-info --pane <a-pane-running-that-cli>
     # two+ processes where Herdr expects one = launcher
     ```
   - Record the launchers as `LAUNCHER_CLIS=<list>`. For those kinds, the skill routes
     around `agent prompt` / `agent send-keys` and uses `pane send-text` /
     `pane send-keys` (these work regardless). The skill already defaults to the
     pane-based commands, so this only shapes which troubleshooting notes to keep.

### Group C: Projects & destination

9. **Projects.** What projects should the assistant track? Get the list now — name,
   one-line description, and path for each. These seed `projects/INDEX.md`.
   - If none yet, the index stays at one row (the assistant's own config) — that's fine.

10. **Destination.** Where should the config live?
    - Default: `~/projects/<slug>/` (e.g. `~/projects/mina/`).
    - Confirm before creating. Create the directory if it does not exist.

---

## Step 2 — Scaffold

1. Copy `template/` to the destination, **excluding** the Herdr skill if `USES_HERDR=false`:
   ```bash
   dest="<destination>"
   mkdir -p "$dest"
   # either run the helper:
   ./scaffold.sh "$dest" $([ "$USES_HERDR" = false ] && echo --no-herdr)
   # …or copy manually: cp -r template/* "$dest"/ and cp -r template/.agents "$dest"/
   ```
   `scaffold.sh` refuses to overwrite an existing non-empty destination — confirm with the
   user before deleting anything.

2. Fill the placeholders. For each file under `$dest`, replace the `{{TOKENS}}`:

   | Token | Source |
   |---|---|
   | `{{ASSISTANT_NAME}}` | Q1 name |
   | `{{ASSISTANT_NAME_SLUG}}` | Q1 slug |
   | `{{ROLE_LABEL}}` | Q2 role |
   | `{{TONE_DESCRIPTION}}` | Q3 tone |
   | `{{DESTINATION_PATH}}` | Q10 destination |
   | `{{SKILLS_LIST}}` | the skills block from Step 3 |
   | `{{MODEL_DEFAULTS_SUMMARY}}` | one line from Q7 (see below) |
   | `{{PROJECT_ROWS}}` / `{{PROJECT_ROW}}` | Q9, one `| slug | what | status | path |` row each |
   | `{{#USES_HERDR}}…{{/USES_HERDR}}` | keep the block if Q6=yes, delete the whole block (incl. markers) if no |
   | `{{#CODING_COORDINATOR}}…{{/CODING_COORDINATOR}}` | keep if Q2=Coding Coordinator, delete the whole block (incl. markers) otherwise |

   `{{MODEL_DEFAULTS_SUMMARY}}` example:
   > Sonnet 5 by default, GLM-5.2 if Sonnet is out of quota; Opus 5 only for genuinely
   > hard work. Gemini 3.6 Flash for review, image analysis, and codebase discovery — not
   > implementation.

3. If `USES_HERDR=true`, fill `template/.agents/skills/herdr-orchestrator/references/models.config.md`
   from Q7/Q8: real provider table, the `--model` value per canonical model, which
   `--kind` integration is installed, and which defaults you routed. Then strip the
   `<!-- CONFIG -->` banners from the skill files you touched.

---

## Step 3 — Assemble the skills list

Build the `{{SKILLS_LIST}}` block that goes into `AGENTS.md`:

- If `USES_HERDR=true`:
  ```
  - `herdr-orchestrator` — delegating to main agents through the Herdr CLI: model routing, launch, monitoring
  ```
- If false, write:
  ```
  (no skills installed yet)
  ```
  and remove the `.agents/skills/herdr-orchestrator/` directory from the destination.

---

## Step 4 — Verify

1. **Bootstrap test.** Start a session in `$dest` as a fresh agent. Confirm it reads
   `AGENTS.md`, then `identity.md`, then `projects/INDEX.md` without errors. Check it
   refers to itself by the chosen name.
2. **Placeholder sweep.** Grep the destination for any leftover `{{` or `}}` or
   `<!-- CONFIG -->`. If any remain, fill or delete them.
3. **Herdr skill (if installed).** From inside a Herdr pane, run the guardrail in
   `SKILL.md` (`[ "$HERDR_ENV" = "1" ] && echo ok`). Confirm the skill's environment
   section is filled with the real `herdr --version`, `herdr integration status`, etc.
4. **Project rows.** Each project from Q9 that has a real path: create a
   `projects/<slug>/` from `_TEMPLATE/` and add its row to `INDEX.md`. (User's choice —
   offer, don't force.)

## Step 5 — Hand off

Tell the user, in one short paragraph:
- where the config lives,
- the assistant's name and role,
- whether the Herdr skill is installed and which model is the default,
- one next action ("open a session in `<dest>` to start").

Do not lecture. They can read `CONFIG.md` and `MODELS.md` themselves.

---

## Rules for the interview

- **Ask, don't assume.** Every placeholder is a question. The one exception is the slug,
  which you derive from the name.
- **Offer defaults, don't force them.** "The default is X — want that, or something else?"
- **Keep turns short.** Group A is one message; B and C can each be one or two.
- **If a question does not apply** (e.g. no Herdr), say so and skip the dependent ones.
- **Never overwrite an existing config** without explicit confirmation. If
  `$dest/AGENTS.md` already exists, stop and ask.
