#!/usr/bin/env bash
# SubagentStop hook — quick sanity check that the just-finished subagent did
# not write outside its declared write scope.
#
# Implementation note: Claude Code does not expose the per-tool write log to
# this hook directly; the check-frozen-paths PreToolUse hook is the primary
# enforcement. This hook is a secondary heuristic that scans /tmp/figma-<runId>/
# for unexpected new top-level files (which would indicate a specialist
# straying from its slice).

set -eo pipefail

# Find the most recent /tmp/figma-* directory
LATEST=$(ls -td /tmp/figma-* 2>/dev/null | head -1)
[[ -z "$LATEST" ]] && exit 0
[[ -d "$LATEST" ]] || exit 0

# Expected files per the manifest protocol:
EXPECTED=(manifest.json shot-*.png scratch sliced-input-*.json)

unexpected=()
for f in "$LATEST"/*; do
  [[ -e "$f" ]] || continue
  base=$(basename "$f")
  match=0
  for pat in "${EXPECTED[@]}"; do
    case "$base" in $pat) match=1; break ;; esac
  done
  [[ "$match" -eq 0 ]] && unexpected+=("$base")
done

if [[ ${#unexpected[@]} -gt 0 ]]; then
  {
    echo "[subagent-scope-check] unexpected files in $LATEST:"
    for f in "${unexpected[@]}"; do echo "  ⚠ $f"; done
    echo "  Specialists should write only manifest.json + screenshots + scratch/."
  } >&2
fi

exit 0
