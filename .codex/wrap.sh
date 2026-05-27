#!/usr/bin/env bash
# Codex CLI wrapper — simulates Claude Code's lifecycle hooks for `codex run <command>`.
#
# Codex doesn't natively support hooks. This wrapper invokes the same hook
# scripts at three lifecycle points:
#
#   pre-command:  configuration sanity, env-access lockout, figma-url nudge
#   post-command: manifest schema check, token syntax check, config schema check
#   on-exit:      session summary
#
# Usage:
#   .codex/wrap.sh <command> [args...]
#
# Examples:
#   .codex/wrap.sh init-figma-compose
#   .codex/wrap.sh figma-build https://figma.com/design/...
#
# Make this the actual entrypoint by aliasing in your shell:
#   alias codex-run='./.codex/wrap.sh'

set -eo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
HOOKS="$REPO_ROOT/.codex/hooks"
COMMAND="${1:-help}"
shift || true
ARGS=("$@")

run_hook() {
  local script="$1"
  [[ -x "$script" ]] || return 0
  if ! "$script" "${ARGS[@]}"; then
    echo "[codex/wrap] hook failed: $script" >&2
    return 1
  fi
}

# ---- pre-command ------------------------------------------------------------
PRE_INPUT=$(jq -nc --arg cmd "$COMMAND" --argjson args "$(printf '%s\n' "${ARGS[@]}" | jq -R . | jq -s .)" '{command: $cmd, args: $args}')
printf '%s' "$PRE_INPUT" | run_hook "$HOOKS/pre-command.sh" || exit $?

# ---- run the command --------------------------------------------------------
CMD_PATH="$REPO_ROOT/.codex/commands/$COMMAND.md"
if [[ ! -r "$CMD_PATH" ]]; then
  echo "[codex/wrap] unknown command: $COMMAND" >&2
  echo "Available commands:" >&2
  ls "$REPO_ROOT/.codex/commands/" 2>/dev/null | sed 's/\.md$//' | sed 's/^/  /' >&2
  exit 1
fi

echo "[codex/wrap] dispatching $COMMAND (see $CMD_PATH for agent recipe)"
EXIT_CODE=0
codex run-agent "$COMMAND" "${ARGS[@]}" || EXIT_CODE=$?

# ---- post-command -----------------------------------------------------------
POST_INPUT=$(jq -nc --arg cmd "$COMMAND" --argjson code "$EXIT_CODE" '{command: $cmd, exitCode: $code}')
printf '%s' "$POST_INPUT" | run_hook "$HOOKS/post-command.sh" || true

# ---- on-exit ----------------------------------------------------------------
run_hook "$HOOKS/on-exit.sh" || true

exit $EXIT_CODE
