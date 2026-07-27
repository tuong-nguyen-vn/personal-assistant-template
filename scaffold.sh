#!/usr/bin/env bash
# scaffold.sh — copy template/ to a destination, optionally without the Herdr skill
# and/or the coding coordination protocol.
#
# Usage:
#   ./scaffold.sh <destination> [--no-herdr] [--no-coding]
#
# Refuses to overwrite a non-empty destination. The agent onboarding flow
# (ONBOARDING.md) calls this; humans can run it too.
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <destination> [--no-herdr] [--no-coding]" >&2
  exit 2
fi

dest="$1"
shift
include_herdr=1
include_coding=1
for arg in "$@"; do
  case "$arg" in
    --no-herdr) include_herdr=0 ;;
    --no-coding) include_coding=0 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src="$script_dir/template"

if [ ! -d "$src" ]; then
  echo "template/ not found next to $0 (looked in $src)" >&2
  exit 1
fi

if [ -e "$dest" ] && [ -n "$(ls -A "$dest" 2>/dev/null)" ]; then
  echo "Destination exists and is not empty: $dest" >&2
  echo "Refusing to overwrite. Remove it first or pick a different path." >&2
  exit 1
fi

mkdir -p "$dest"

# Copy visible files.
cp -r "$src"/* "$dest"/

# Copy dotfiles (.agents) — cp -r src/* skips them.
if [ -d "$src/.agents" ]; then
  mkdir -p "$dest/.agents"
  cp -r "$src/.agents"/. "$dest/.agents"/
fi

# Optionally drop the Herdr skill.
if [ "$include_herdr" -eq 0 ]; then
  rm -rf "$dest/.agents/skills/herdr-orchestrator"
  # If .agents is now empty, leave it — pi still discovers it.
fi

# Optionally drop the coding coordination protocol.
if [ "$include_coding" -eq 0 ]; then
  rm -rf "$dest/coding"
fi

echo "Scaffolded into: $dest"
if [ "$include_herdr" -eq 1 ]; then
  echo "Herdr skill: included"
else
  echo "Herdr skill: skipped (--no-herdr)"
fi
if [ "$include_coding" -eq 1 ]; then
  echo "Coding protocol: included"
else
  echo "Coding protocol: skipped (--no-coding)"
fi
echo "Next: fill the {{PLACEHOLDERS}} (see ONBOARDING.md or CONFIG.md)."
