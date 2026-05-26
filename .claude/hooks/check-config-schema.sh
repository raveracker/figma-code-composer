#!/usr/bin/env bash
# PostToolUse hook — when a write touches .figma-pipeline/config.json, validate
# against config.schema.json. Reports as a warning (non-blocking) so the wizard
# can finish its sequence even if intermediate writes drift.

set -eo pipefail

INPUT="$(cat 2>/dev/null || true)"
TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || echo '')"
case "$TOOL_NAME" in Write|Edit|MultiEdit) ;; *) exit 0 ;; esac

FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo '')"
[[ -z "$FILE_PATH" ]] && exit 0
[[ "$FILE_PATH" =~ \.figma-pipeline/config\.json$ ]] || exit 0
[[ -r "$FILE_PATH" ]] || exit 0

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SCHEMA="$REPO_ROOT/.figma-pipeline/config.schema.json"
[[ -r "$SCHEMA" ]] || exit 0

if command -v npx >/dev/null 2>&1; then
  if RESULT=$(npx --yes --offline ajv-cli@5 validate -s "$SCHEMA" -d "$FILE_PATH" 2>&1); then
    : # OK
  else
    {
      echo "[check-config-schema] $FILE_PATH does not validate against config.schema.json"
      echo "$RESULT" | head -20
    } >&2
  fi
elif command -v jq >/dev/null 2>&1; then
  # Minimal structural check fallback
  problems=()
  for required in version project framework language cssSystem tokens components icons writeScope; do
    jq -e "has(\"$required\")" "$FILE_PATH" >/dev/null 2>&1 || problems+=("missing top-level key: $required")
  done
  VERSION=$(jq -r '.version // empty' "$FILE_PATH" 2>/dev/null)
  [[ "$VERSION" == "1.0" ]] || problems+=("version must be \"1.0\" (got \"${VERSION:-MISSING}\")")
  if [[ ${#problems[@]} -gt 0 ]]; then
    {
      echo "[check-config-schema] structural check found issues in $FILE_PATH:"
      for p in "${problems[@]}"; do echo "  ⚠ $p"; done
      echo "  Install ajv-cli for full JSON Schema validation: npm i -g ajv-cli"
    } >&2
  fi
fi

exit 0
