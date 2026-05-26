#!/usr/bin/env bash
# Codex on-exit hook — minimal session summary.

set -eo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
CHANGED=$(git -C "$REPO_ROOT" status --short 2>/dev/null | head -10 || true)
LATEST_RUN=$(ls -td /tmp/figma-* 2>/dev/null | head -1 || true)

if [[ -z "$CHANGED" && -z "$LATEST_RUN" ]]; then
  exit 0
fi

{
  echo ""
  echo "─── codex session summary ───"
  [[ -n "$CHANGED" ]] && echo "Working tree:" && echo "$CHANGED" | sed 's/^/  /'
  [[ -n "$LATEST_RUN" ]] && echo "Last run scratch: $LATEST_RUN"
  echo "─────────────────────────────"
} >&2

exit 0
