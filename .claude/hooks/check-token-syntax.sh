#!/usr/bin/env bash
# PostToolUse hook — when token-builder writes a token file inside
# config.tokens.outputDir, do a minimal syntax sanity check appropriate for
# the configured token strategy. Reports as a warning (non-blocking).

set -eo pipefail

INPUT="$(cat 2>/dev/null || true)"
TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || echo '')"
case "$TOOL_NAME" in Write|Edit|MultiEdit) ;; *) exit 0 ;; esac

FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo '')"
[[ -z "$FILE_PATH" ]] && exit 0
[[ -r "$FILE_PATH" ]] || exit 0

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
CONFIG="$REPO_ROOT/.figma-pipeline/config.json"
[[ -r "$CONFIG" ]] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

TOKENS_DIR=$(jq -r '.tokens.outputDir // empty' "$CONFIG" 2>/dev/null)
[[ -z "$TOKENS_DIR" ]] && exit 0

REL_PATH="${FILE_PATH#$REPO_ROOT/}"
[[ "$REL_PATH" == "$TOKENS_DIR"* || "$REL_PATH" == "$TOKENS_DIR/"* ]] || exit 0

STRATEGY=$(jq -r '.tokens.strategy // empty' "$CONFIG" 2>/dev/null)

problems=()
case "$STRATEGY" in
  tailwind-css-vars|css-custom-properties)
    # CSS files — check brace balance + reject obvious patterns
    if [[ "$FILE_PATH" == *.css ]]; then
      OPEN=$(grep -c '{' "$FILE_PATH" 2>/dev/null || echo 0)
      CLOSE=$(grep -c '}' "$FILE_PATH" 2>/dev/null || echo 0)
      [[ "$OPEN" -eq "$CLOSE" ]] || problems+=("brace mismatch: $OPEN '{' vs $CLOSE '}'")
      grep -qE '^\s*[a-zA-Z][^:]*:\s*;\s*$' "$FILE_PATH" 2>/dev/null && problems+=("empty value detected (declaration with no RHS)")
    fi
    ;;
  scss-variables)
    if [[ "$FILE_PATH" == *.scss ]]; then
      OPEN=$(grep -c '{' "$FILE_PATH" 2>/dev/null || echo 0)
      CLOSE=$(grep -c '}' "$FILE_PATH" 2>/dev/null || echo 0)
      [[ "$OPEN" -eq "$CLOSE" ]] || problems+=("brace mismatch: $OPEN '{' vs $CLOSE '}'")
    fi
    ;;
  js-tokens|unocss-theme)
    # Defer to TS compiler at build time; just check it's not literally empty
    [[ -s "$FILE_PATH" ]] || problems+=("file is empty")
    ;;
esac

if [[ ${#problems[@]} -gt 0 ]]; then
  {
    echo "[check-token-syntax] $REL_PATH"
    for p in "${problems[@]}"; do echo "  ⚠ $p"; done
  } >&2
fi

exit 0
