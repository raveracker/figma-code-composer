#!/usr/bin/env bash
# PreToolUse hook — config-driven write-access allowlist.
#
# Reads .figma-pipeline/config.json and blocks any Write/Edit/MultiEdit whose
# target is not inside config.writeScope.allowedDirs (or the bootstrap default
# allowlist when no config exists yet).
#
# Always-blocked: config.writeScope.alwaysBlocked + standard lockfiles + .env*.
#
# Escape hatch: FP_ALLOW_RESTRICTED_WRITE=1 (or legacy HK_ALLOW_RESTRICTED_WRITE=1).
#
# Exit codes:
#   0 = allow
#   2 = block

set -eo pipefail

INPUT="$(cat 2>/dev/null || true)"
TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || echo '')"

case "$TOOL_NAME" in
  Write|Edit|MultiEdit) ;;
  *) exit 0 ;;
esac

FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo '')"
[[ -z "$FILE_PATH" ]] && exit 0

if [[ "${HK_ALLOW_RESTRICTED_WRITE:-}" == "1" || "${FP_ALLOW_RESTRICTED_WRITE:-}" == "1" ]]; then
  exit 0
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
REL_PATH="${FILE_PATH#$REPO_ROOT/}"
CONFIG="$REPO_ROOT/.figma-pipeline/config.json"

ALWAYS_BLOCKED_GLOBS=(
  "node_modules/**"
  "dist/**"
  "build/**"
  ".next/**"
  ".turbo/**"
  "coverage/**"
  "package-lock.json"
  "yarn.lock"
  "pnpm-lock.yaml"
  ".env"
  ".env.*"
)

matches_glob() {
  local path="$1" pattern="$2"
  case "$path" in
    $pattern) return 0 ;;
  esac
  return 1
}

for pat in "${ALWAYS_BLOCKED_GLOBS[@]}"; do
  if matches_glob "$REL_PATH" "$pat"; then
    echo "[check-frozen-paths] BLOCKED (always-blocked): $REL_PATH matches $pat" >&2
    echo "Set FP_ALLOW_RESTRICTED_WRITE=1 only if you intentionally need to bypass." >&2
    exit 2
  fi
done

if [[ -r "$CONFIG" ]] && command -v jq >/dev/null 2>&1; then
  # Read globs portably (bash 3.2 — no mapfile/readarray on default macOS bash).
  CFG_GLOBS=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && CFG_GLOBS+=("$line")
  done < <(jq -r '.writeScope.allowedDirs[]?' "$CONFIG" 2>/dev/null)
  CFG_BLOCKED=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && CFG_BLOCKED+=("$line")
  done < <(jq -r '.writeScope.alwaysBlocked[]?' "$CONFIG" 2>/dev/null)
  for pat in "${CFG_BLOCKED[@]}"; do
    if matches_glob "$REL_PATH" "$pat"; then
      echo "[check-frozen-paths] BLOCKED (config alwaysBlocked): $REL_PATH matches $pat" >&2
      exit 2
    fi
  done
  ALLOWED_GLOBS=("${CFG_GLOBS[@]}" ".figma-pipeline/**" "/tmp/**" ".mcp.json" ".codex/**")
else
  ALLOWED_GLOBS=(".figma-pipeline/**" "/tmp/**" ".mcp.json" ".codex/**")
fi

for pat in "${ALLOWED_GLOBS[@]}"; do
  if matches_glob "$REL_PATH" "$pat"; then
    exit 0
  fi
  if [[ "$pat" == "/tmp/**" && "$FILE_PATH" == /tmp/* ]]; then
    exit 0
  fi
done

echo "[check-frozen-paths] BLOCKED: $REL_PATH is not in the configured write allowlist." >&2
echo "Allowed roots:" >&2
for pat in "${ALLOWED_GLOBS[@]}"; do
  echo "  - $pat" >&2
done
echo "Set FP_ALLOW_RESTRICTED_WRITE=1 to bypass (owner-driven config/hook edits only)." >&2
exit 2
