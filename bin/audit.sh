#!/usr/bin/env bash
# audit.sh — print what this machine actually has: agent CLIs, providers, models, Herdr
# integrations. Read-only. Run any time the setup feels stale; diff against the recorded
# values in models.config.md (or .agents/skills/herdr-orchestrator/references/models.config.md
# if the Herdr skill is installed).
#
# Usage: ./bin/audit.sh
set -u

have() { command -v "$1" >/dev/null 2>&1; }

echo "# Audit — $(date -u +%FT%TZ)"
echo

echo "## Agent CLIs on PATH"
for cli in pi amp-pi claude codex gemini cursor devin copilot opencode cline agy aider \
          omp mastracode kimi kiro droid amp grok hermes kilo qodercli maki; do
  if have "$cli"; then
    ver=$("$cli" --version 2>/dev/null | head -1 | tr -d '\n')
    printf -- "- %s: %s\n" "$cli" "${ver:-<no --version>}"
  fi
done
echo

echo "## Herdr"
if have herdr; then
  herdr --version 2>/dev/null | sed 's/^/herdr /'
  if [ "${HERDR_ENV:-}" = "1" ]; then
    echo "HERDR_ENV=1 (in a Herdr pane)"
    herdr integration status 2>/dev/null | sed 's/^/  /'
  else
    echo "HERDR_ENV not set — run from inside a Herdr pane to see integration status."
  fi
else
  echo "herdr: not found"
fi
echo

echo "## Providers and models pi can reach"
if have pi; then
  pi --list-models 2>/dev/null | sort -u | sed 's/^/- /'
else
  echo "pi: not found — cannot enumerate. List provider keys manually in models.config.md."
fi
echo

echo "## Other tools"
have jq && echo "jq: $(jq --version)" || echo "jq: missing (the skill needs it to parse JSON)"
echo
echo "Diff this against models.config.md. Edit that one file — no reinstall needed."
