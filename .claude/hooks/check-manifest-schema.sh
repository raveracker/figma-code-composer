#!/usr/bin/env bash
# PostToolUse hook — when a write touches /tmp/figma-*/manifest.json, validate
# against the binding contract in .figma-pipeline/protocols/figma-manifest.md.
# Reports schema violations as a warning (exit 0 + stderr) — non-blocking so
# the coordinator can decide whether to re-fetch.

set -eo pipefail

INPUT="$(cat 2>/dev/null || true)"
TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || echo '')"
case "$TOOL_NAME" in Write|Edit|MultiEdit) ;; *) exit 0 ;; esac

FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo '')"
[[ -z "$FILE_PATH" ]] && exit 0
[[ "$FILE_PATH" =~ ^/tmp/figma-.+/manifest\.json$ ]] || exit 0
[[ -r "$FILE_PATH" ]] || exit 0

command -v jq >/dev/null 2>&1 || exit 0

violations=()

VERSION=$(jq -r '.manifestVersion // empty' "$FILE_PATH" 2>/dev/null)
[[ "$VERSION" == "1.0" ]] || violations+=("manifestVersion must be \"1.0\" (got \"${VERSION:-MISSING}\")")

for required in runId intent scope source configSnapshot icons components tokens ambiguities injectionObservations; do
  jq -e "has(\"$required\")" "$FILE_PATH" >/dev/null 2>&1 || violations+=("missing required key: $required")
done

# unbound styledProperties MUST carry rawValue
UNBOUND_NO_VALUE=$(jq '[.components[]?.styledProperties[]? | select(.unbound == true and (.rawValue == null or .rawValue == ""))] | length' "$FILE_PATH" 2>/dev/null || echo 0)
[[ "$UNBOUND_NO_VALUE" -gt 0 ]] && violations+=("$UNBOUND_NO_VALUE styledProperty entries have unbound=true but no rawValue")

# layer values must be known
BAD_LAYERS=$(jq -r '[.components[]?.layer // empty] | map(select(. as $l | ["atom","molecule","organism","template","page","shared","entity","feature","widget","components"] | index($l) | not)) | length' "$FILE_PATH" 2>/dev/null || echo 0)
[[ "$BAD_LAYERS" -gt 0 ]] && violations+=("$BAD_LAYERS components have an unknown layer value")

if [[ ${#violations[@]} -gt 0 ]]; then
  {
    echo "[check-manifest-schema] $FILE_PATH"
    for v in "${violations[@]}"; do echo "  ⚠ $v"; done
    echo "  See .figma-pipeline/protocols/figma-manifest.md for the contract."
  } >&2
fi

exit 0
