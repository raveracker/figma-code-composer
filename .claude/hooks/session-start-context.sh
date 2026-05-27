#!/usr/bin/env bash
# SessionStart hook — print figma-pipeline status + branch.

set -eo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
CONFIG="$REPO_ROOT/.figma-pipeline/config.json"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '(no git)')"

echo "📐 figma-to-code orchestration"
echo "   Branch: $BRANCH"

if [[ -r "$CONFIG" ]]; then
  if command -v jq >/dev/null 2>&1; then
    NAME=$(jq -r '.project.name // "(unset)"' "$CONFIG")
    FW=$(jq -r '.framework.name // "?"' "$CONFIG")
    VAR=$(jq -r '.framework.variant // empty' "$CONFIG")
    CSS=$(jq -r '.cssSystem.name // "?"' "$CONFIG")
    METHOD=$(jq -r '.components.designMethodology // "?"' "$CONFIG")
    DS=$(jq -r '.designSystem.name // "none"' "$CONFIG")
    DSTHEME=$(jq -r '.designSystem.themeName // empty' "$CONFIG")
    echo "   Project: $NAME — $FW${VAR:+ ($VAR)} + $CSS + $METHOD"
    [[ "$DS" != "none" ]] && echo "   Design system: $DS${DSTHEME:+ ($DSTHEME)}"
  else
    echo "   .figma-pipeline/config.json present (install jq for details)"
  fi
else
  echo "   ⚠️  No .figma-pipeline/config.json — run /init-figma-compose to configure"
fi
