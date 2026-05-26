#!/usr/bin/env bash
# PreToolUse hook — STRICT block on ALL access (Read AND Write/Edit AND Bash)
# to any `.env` secrets file in the repo.
#
# Policy: the root `.env` (and `.env.local`, `.env.*` — anything except the
# committed `.env.example` template) holds live secrets. The agent must never
# read or modify it.
#
# Bypass (BOTH required — deliberately stricter than check-frozen-paths.sh,
# which needs only FP_ALLOW_RESTRICTED_WRITE):
#   1. FP_ALLOW_RESTRICTED_WRITE=1   (legacy HK_ALLOW_RESTRICTED_WRITE=1 also accepted)
#   2. FP_ENV_ACCESS_PASSWORD=allowenv   (legacy HK_ENV_ACCESS_PASSWORD=allowenv also accepted)
# Either one alone does NOT unlock it.
#
# Blocks with exit 2 (repo convention) so the model gets the reason back.

INPUT="$(cat 2>/dev/null || true)"
TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || echo '')"

# ---- dual bypass ------------------------------------------------------------
_unlock="${FP_ALLOW_RESTRICTED_WRITE:-${HK_ALLOW_RESTRICTED_WRITE:-}}"
_pwd="${FP_ENV_ACCESS_PASSWORD:-${HK_ENV_ACCESS_PASSWORD:-}}"
if [[ "$_unlock" == "1" && "$_pwd" == "allowenv" ]]; then
  exit 0
fi

# Returns 0 (match) if $1 names a protected .env file (not *.example).
is_protected_env_path() {
  local base
  base="$(basename -- "$1")"
  case "$base" in
    .env.example|.env.*.example) return 1 ;;   # template — allowed
    .env|.env.*) return 0 ;;                    # secret — protected
    *) return 1 ;;
  esac
}

BLOCK_MSG="BLOCKED: access to a .env secrets file is forbidden (owner policy). \
Only the committed .env.example template is accessible. To override you must set \
BOTH FP_ALLOW_RESTRICTED_WRITE=1 AND FP_ENV_ACCESS_PASSWORD=allowenv in the shell \
environment — neither alone is sufficient."

case "$TOOL_NAME" in
  Read|Edit|Write|MultiEdit|NotebookEdit)
    FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null || echo '')"
    [[ -z "$FILE_PATH" ]] && exit 0
    if is_protected_env_path "$FILE_PATH"; then
      printf '%s\nPath: %s\n' "$BLOCK_MSG" "$FILE_PATH" >&2
      exit 2
    fi
    ;;
  Grep)
    # Grep can exfiltrate a .env's contents (output_mode=content). Block when
    # the target path is a .env file or the glob targets .env (not .example).
    GPATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.path // empty' 2>/dev/null || echo '')"
    GGLOB="$(printf '%s' "$INPUT" | jq -r '.tool_input.glob // empty' 2>/dev/null || echo '')"
    if [[ -n "$GPATH" ]] && is_protected_env_path "$GPATH"; then
      printf '%s\nGrep path: %s\n' "$BLOCK_MSG" "$GPATH" >&2
      exit 2
    fi
    if [[ -n "$GGLOB" ]]; then
      case "$GGLOB" in
        *.env.example|*.env.*.example) : ;;
        *.env|*.env.*|.env|.env.*) printf '%s\nGrep glob: %s\n' "$BLOCK_MSG" "$GGLOB" >&2; exit 2 ;;
      esac
    fi
    ;;
  Bash)
    CMD="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || echo '')"
    [[ -z "$CMD" ]] && exit 0
    # Find filename-like `.env` / `.env.<x>` tokens that sit on a path
    # boundary (so `process.env` / `NODE_ENV` do NOT match), drop the
    # leading boundary char, then remove the allowed `.env.example`.
    HITS="$(printf '%s' "$CMD" \
      | grep -oE '(^|[^A-Za-z0-9_.])\.env(\.[A-Za-z0-9_]+)?' 2>/dev/null \
      | sed -E 's/^[^.]*//' \
      | grep -vxE '\.env\.example' 2>/dev/null || true)"
    if [[ -n "$HITS" ]]; then
      printf '%s\nCommand referenced: %s\n' "$BLOCK_MSG" "$(printf '%s' "$HITS" | tr '\n' ' ')" >&2
      exit 2
    fi
    ;;
  *) exit 0 ;;
esac

exit 0
