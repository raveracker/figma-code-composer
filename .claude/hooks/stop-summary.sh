#!/usr/bin/env bash
# Stop hook — quick session summary surfacing any pending pipeline artifacts
# the user should review (uncommitted changes inside allowed dirs, leftover
# /tmp/figma-* runs).

set -eo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
CONFIG="$REPO_ROOT/.figma-pipeline/config.json"

# Touched files since session start (cheap heuristic: git status)
CHANGED=$(git -C "$REPO_ROOT" status --short 2>/dev/null | head -20 || true)
RUNS=$(ls -d /tmp/figma-* 2>/dev/null | tail -3 || true)

if [[ -z "$CHANGED" && -z "$RUNS" ]]; then
  exit 0
fi

{
  echo ""
  echo "─── figma-pipeline session summary ───"
  if [[ -n "$CHANGED" ]]; then
    echo "Working tree (uncommitted — owner-only to commit):"
    echo "$CHANGED" | sed 's/^/  /'
  fi
  if [[ -n "$RUNS" ]]; then
    echo "Recent /tmp/figma-* runs:"
    echo "$RUNS" | sed 's/^/  /'
  fi
  if [[ -r "$CONFIG" ]] && command -v jq >/dev/null 2>&1; then
    NAME=$(jq -r '.project.name // ""' "$CONFIG" 2>/dev/null)
    [[ -n "$NAME" ]] && echo "Project: $NAME"
  fi
  echo "──────────────────────────────────────"
} >&2

exit 0
