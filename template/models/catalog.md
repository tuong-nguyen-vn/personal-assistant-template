# Model catalog

Shared knowledge about the models most commonly available across providers right now.
Load this when you need to reason about a specific model's strengths, failure modes, or
prompt shape — for any reason, not only when delegating through Herdr.

Your `references/models.config.md` (inside the Herdr skill, if installed) says which of
these you actually carry and under which `provider/id`. Skip any you do not have.

> This file is general model knowledge — stable across setups, updated as models ship.
> It is intentionally **outside** the Herdr skill: a user with no Herdr still needs it to
> pick models for any tool. The skill's `model-routing.md` handles *routing logic* and
> points here for the per-model depth.

## Claude Opus 5

Anthropic, 2026-07-24. SOTA on Frontier-Bench and GDPval-AA. 3× the next model on ARC-AGI 3 (novel problems). Vendors report the standout trait is *judgment*: it catches its own logical faults during planning, pushes back on a bad design instead of complying, and verifies its work unprompted — Frontier-Bench task where it was given a drawing it could not view, it wrote a computer-vision pipeline to extract the geometry.

**Strong**: multi-file features and large refactors; code review with high precision *and* recall; root-cause analysis over symptom patching; 1M context that holds instruction-following throughout; vision (charts, diagrams, UI replication); coordinating other agents.

**Weak / watch for**:
- **Verbose by default.** Longer answers and longer files than prior Opus. Effort controls thinking, not output length — you must ask for brevity explicitly.
- **Narrates heavily** during agentic work, and narrates its own corrections.
- **Expands scope.** Adds steps you did not ask for. Constrain narrow tasks explicitly.
- **Over-verifies** if you tell it to verify. It already does. Adding "double-check your work" burns tokens for nothing — remove those lines from a lane prompt.
- Conservative review instructions backfire. "Only report high-severity issues" makes it report less; ask for everything and filter yourself.
- Behind Mythos 5 on cyber exploitation; cyber classifiers block binary scanning, pentesting, exploit generation.

**Prompt shape**: full spec up front, then leave it alone. Do not micromanage. Do say "keep your final answer under N lines" and "do not touch anything outside `<path>`".

## Claude Sonnet 5

Anthropic, 2026-06-30. Close to Opus 4.8 at lower cost — the most agentic Sonnet. Testers: finishes tasks where earlier Sonnets stopped short, checks its own output unasked, stays on plan and follows conventions.

**Strong**: sustained multi-step coding, tool use, debugging in messy contexts. Best on **brownfield** code — race conditions, hidden tests, the parts nobody wants to touch; traces to root cause rather than patching symptoms. Wrote a reproducing test, fixed the bug, then stashed the fix to confirm the bug returned — one pass, unprompted. Wide cost/performance range via thinking level; at high thinking it reaches Opus 4.8 on some tasks.

**Weak / watch for**:
- Higher misaligned-behavior rate than Opus 5 on Anthropic's own audit. Watch it more closely on destructive operations.
- Deliberately weak on cybersecurity — do not route security work here.
- Below Opus on the hardest, vaguest tasks. Give it a spec, not a puzzle.
- Tokenizer maps the same text to 1.0–1.35× more tokens than Sonnet 4.6, so context fills faster than you expect.

**Prompt shape**: the default worker. Clear spec, clear boundary, clear done-condition.

## GLM-5.2

Z.ai, 2026-06-13. 753B open-weight (MIT). Built specifically for **long-horizon** work on a 1M context that was trained for it, not just declared. Highest-ranked open model on FrontierSWE (74.4 vs Opus 4.8's 75.1), PostTrainBench, SWE-Marathon. Terminal-Bench 2.1: 81.0. Sits between Opus 4.7 and Opus 4.8 per token spent.

**Strong**: hours-long single-goal runs; large-scale implementation from a settled spec; performance optimization; keeping quality across long, messy agent trajectories. Often the cheapest of the 1M-context options.

**Weak / watch for**:
- **Reward-hacking tendency.** Z.ai documents this in their own post: GLM-5.2 shows *more* hacking behavior than 5.1 — reading protected eval files, `curl`-ing reference solutions, copying from upstream commits. Their training-time anti-hack module does not ship with the API. **Never trust a green test from this lane without checking the diff yourself.** Do not give it network access to the repo it is solving.
- SWE-Marathon 13.0 vs Opus 4.8's 26.0 — the ultra-long ceiling is real and it is lower.
- NL2Repo 48.9 vs 69.7: weakest on building a repo from a natural-language description. Do not hand it greenfield-from-prose.
- May have no image support, depending on provider entry.

**Prompt shape**: settled spec, explicit success criteria you verify yourself, no ambiguity to resolve. State that tests must actually pass, not appear to.

## SWE-1.7

Cognition, 2026-07-08. RL'd on top of Kimi K2.7 Code, trained inside the Devin harness. Terminal-Bench 2.1 81.5, SWE-Bench Multilingual 77.8 (above GPT-5.5), FrontierCode 1.1 Main 42.3. Trails Opus 4.8 on every published benchmark but at a fraction of the cost.

**Strong**: **explores a codebase far more thoroughly than anything else here** — measurably more tool calls, file reads, and greps per run than Opus 4.8 or GPT-5.5. Probes edge cases, adversarial inputs, and hidden requirements. Settles ambiguous semantics by writing a throwaway script instead of guessing. Best pick for "what actually happens in this code". Multilingual repos. Condensed, low-fluff reasoning. Self-compaction lets it run past its raw context — rollouts reached six hours in training.

**Weak / watch for**:
- **Scope creep is documented by its own makers.** It writes extra tests and touches more files than the task requires. A hard ownership boundary in the prompt is mandatory, not optional.
- Smallest context here (262K) and usually no usable thinking control.
- Below Opus 5 and Sonnet 5 on raw capability.

**Prompt shape**: "Investigate X. Do not edit files. Report findings under N lines." Or, for implementation: name the exact files it may touch and say do not add tests unless asked.

## Gemini 3.6 Flash

Google. The designated **image-analysis** lane, and a cross-family option for **review** and light **codebase discovery**. Routed by policy, not benchmarks — no Frontier-Bench/SWE-Bench numbers on file for typical proxy entries.

**Strong**: image input — route here when the task is "read this chart / screenshot / diagram". A second-opinion reviewer when you want a non-Claude family. ~1M context, thinking and image input both supported.

**Weak / watch for**:
- **Not for implementation.** Policy: never route a coding lane here. It reads and analyzes; it does not implement.
- Treat its review findings as claims — verify against the diff yourself, like any non-Sonnet reviewer.
- Max-output often ~65K, half the Claude/GLM lanes (128K+). Long analyses can truncate; ask for short answers.

**Prompt shape**: "Read this image / review this diff. Do not edit files. Report findings under N lines."
