# <Project name>

<!-- TIER 2. Loaded when working on this project. Budget: ~2500 chars.
     If a section outgrows the budget, move the detail into notes/ and leave a pointer. -->

**Slug**: `<slug>` · **Status**: active · **Path**: `<absolute path>` · **Updated**: YYYY-MM-DD

## Purpose

One or two sentences. What this project is for and who it serves.

## Stack

Language, framework, runtime, database, deploy target. Only what affects decisions.

## Commands

```bash
# install / dev / build
```

## Verify

The command(s) that prove the project works. **Run this before reporting any coding task done.** If empty, "done" is unverified by definition.

```bash
# e.g. pnpm test && pnpm lint · cargo test · go test ./... · pytest -q
```

## Risk areas

Where a small change breaks the system. Flag before delegating or editing here; prefer a narrow lane and run the full Verify, not a subset.

e.g. `auth/`, `migrations/`, `billing/`, DB schema, payment webhooks.

## Don't break

Invariants that look wrong but are intentional. Must not be broken without an explicit decision.

## Conventions

Naming, commit style, branch strategy, review policy. If unstated, ask before committing.

## Current focus

What is being worked on right now, and what is blocking it. Delete when it ships.

## Open items

- [ ] item

## Tier 3

Load only when the task needs it.

- `DECISIONS.md` — what was decided and why
- `KNOWLEDGE.md` — domain and business rules
- `notes/<topic>.md` — one line on what is inside
