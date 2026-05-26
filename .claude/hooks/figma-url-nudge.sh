#!/usr/bin/env bash
# UserPromptSubmit hook — when a Figma URL is present in the prompt, surface
# routing guidance so the agent picks the right slash command instead of
# improvising.
#
# Stdin: full JSON payload (the wrapper in settings.json tees it to a tmp file
# and pipes the same payload here).

set -eo pipefail

PAYLOAD="$(cat 2>/dev/null || true)"
[[ -z "$PAYLOAD" ]] && exit 0

PROMPT="$(printf '%s' "$PAYLOAD" | jq -r '.prompt // ""' 2>/dev/null || echo '')"
[[ -z "$PROMPT" ]] && exit 0

if printf '%s' "$PROMPT" | grep -qE 'figma\.com/(design|board|make|proto|file)/'; then
  cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"📐 Figma URL detected. Pick the right entry point:\n  • Build NEW components/icons/tokens → /figma-build <url> [layerHint]\n  • UPDATE existing → /figma-update <url>\n  • Icons only → /figma-icons <url>\n  • Tokens only → /figma-tokens <url>\nAll routes spawn figma-coordinator. Do NOT call figma-fetcher / component-builder / etc. directly — the coordinator orchestrates."}}
EOF
fi

exit 0
