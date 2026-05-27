#!/usr/bin/env bash
# Codex pre-command hook — runs before every `codex run <cmd>`.
#
# Enforces CLAUDE.md binding rules at command start:
#
#   [rule 1] config.json must exist (allowlist source) — refuse if missing (except for `init-figma-compose`).
#   [rule 1, supporting] .env access is hard-blocked (read AND write).
#   Routing (rules 1+2): figma.com URLs are nudged toward /figma-* commands so
#     every build goes through the coordinator and the manifest contract.

set -eo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
CONFIG="$REPO_ROOT/.figma-pipeline/config.json"

CMD="${1:-}"

# [rule 1] Allow the wizard to run without config; everything else requires the allowlist source.
case "$CMD" in
  init|init-figma-compose) ;;
  *)
    if [[ ! -r "$CONFIG" ]]; then
      echo "[codex/pre-command] [rule 1] no .figma-pipeline/config.json — run 'codex run init-figma-compose' first" >&2
      exit 1
    fi
    ;;
esac

# Figma URL nudge
for arg in "$@"; do
  if printf '%s' "$arg" | grep -qE 'figma\.com/(design|board|make|proto|file)/'; then
    cat <<'EOF' >&2

📐 Figma URL detected. The right entry points are:
  codex run figma-build <url> [layerHint]   # NEW components/icons/tokens
  codex run figma-update <url>              # UPDATE existing
  codex run figma-icons  <url>              # icons only
  codex run figma-tokens <url>              # tokens only

All routes dispatch the figma-coordinator agent.
EOF
    break
  fi
done

# .env access lockout — if any arg literally matches .env or .env.* (not .env.example), refuse
for arg in "$@"; do
  base=$(basename -- "$arg" 2>/dev/null || true)
  case "$base" in
    .env.example|.env.*.example) : ;;
    .env|.env.*)
      echo "[codex/pre-command] [rule 1] BLOCKED: access to .env secrets file ($arg). Use .env.example." >&2
      exit 2
      ;;
  esac
done

exit 0
