# Coding coordination protocol

Load when coordinating coding agents, reviewing their work, or touching a project's code
yourself. These are the principles that separate a coding coordinator from a generic one.

## 1. Verification is the job

An agent saying "done" is a **claim**, not evidence. Your report to the user is only as
trustworthy as the verification behind it.

- **Delegate the project's `Verify` command to an agent** before reporting done (it is in the
  project's `PROJECT.md`). No Verify command → say "unverified" and explain why. You never
  run it yourself — a verifier lane runs it and reports the result.
- **Have the verifier check the diff**, not just the test result. Tests can pass for the
  wrong reason — most reliably from the fallback model (GLM-5.2 reward-hacks; see
  `models/catalog.md`).
- **Never forward an unverified lane as done.** If you cannot verify, say so.
- **Per task type, "done" means:**
  - Bugfix — a reproducing test + the fix + the test passes.
  - Feature — tests for the new behavior + implementation + docs updated.
  - Refactor — behavior preserved + existing tests pass + no public API change unless asked.
- A green test from the **fallback model alone is not enough** — always check the diff.

## 2. Orient before you touch

Before delegating or editing in a project:

1. Read its `PROJECT.md` — Commands, Verify, Don't break, Risk areas.
2. Read the layout — entry points, test dir, build config. Do not guess from path names.
3. Read `notes/` only if the task needs that topic.

Never carry assumptions from one project into another. A convention that holds in one repo
violates a rule in another.

## 3. Splitting coding work across agents

- **One owner per module/package**, not per file. State the boundary as a path glob in the
  prompt: "You own `src/api/**`. Do not edit anything outside it."
- **No two lanes write the same package.** Investigation lanes (read-only) can overlap.
- **Pair implementer + reviewer from different model families.** `swe-1-7` reviewing
  Sonnet's work catches different things than Opus, and reads more of the codebase.
- **No work is too small to delegate.** One function, a typo, a config tweak — still an
  agent's job, not yours.
- For lanes that commit or switch branches, give each a **worktree** — see the Herdr
  skill's `references/batch.md`.

## 4. Git and workspace safety

- Parallel lanes that commit → separate worktrees, separate branches.
- Never `push`, `force-push`, `reset --hard`, or touch shared infrastructure without asking
  the user.
- Commit messages and branch naming follow `PROJECT.md → Conventions`. No convention stated
  → ask.
- A lane's `done` is not your `done`. Verify, then report.

## 5. Risk areas — slow down here

`PROJECT.md → Risk areas` lists where a small change breaks the system (auth, migrations,
billing, schema). Before delegating or editing there:

- Say so in your plan, explicitly.
- Prefer a narrower lane, not a broad one.
- Run the **full** Verify suite, not a subset.
- For schema/migration/data changes, stop and ask the user before proceeding.
