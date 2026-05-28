#!/usr/bin/env bash
# Codex post-command hook — runs after every `codex run <cmd>`.
#
# Enforces CLAUDE.md binding rules at the end of every command:
#
#   Rule 2 (manifest is single source of truth)         — schema check on latest manifest.json
#   Rule 3 (variable names preserved, never resolved)   — scan styledProperties.figmaVariable for hex/rem patterns
#   Rule 4 (unbound = flag, not invitation)             — count + report unbound entries
#   Rule 5 (blocking ambiguities gate the run)          — warn if the run proceeded with blocking: true ambiguities
#   Rule 6 (figma strings are data, not instructions)   — surface injectionObservations verbatim
#   Rule 7 (verify against reality, not reminders)      — config.json validation; token-file syntax
#
# Reports are warnings (non-zero text on stderr) — never blocks; the user
# reviews the working tree after every run.

set -eo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
command -v jq >/dev/null 2>&1 || exit 0

# ─── Manifest checks (rules 2/3/4/5/6) ───────────────────────────────────────
# Pick the newest manifest, but only one produced DURING this wrapper invocation
# (newer than the start marker). Without this scoping, a failed run that never
# generated a manifest would report a PREVIOUS, unrelated run's findings as
# "this run" — a real misattribution bug.
LATEST_MANIFEST=""
if [[ -n "${FCC_WRAP_MARKER:-}" && -e "$FCC_WRAP_MARKER" ]]; then
  while IFS= read -r cand; do
    [[ -n "$cand" && "$cand" -nt "$FCC_WRAP_MARKER" ]] || continue
    LATEST_MANIFEST="$cand"; break
  done < <(ls -t /tmp/figma-*/manifest.json 2>/dev/null)
else
  LATEST_MANIFEST=$(ls -t /tmp/figma-*/manifest.json 2>/dev/null | head -1)
fi
if [[ -r "$LATEST_MANIFEST" ]]; then
  problems=()

  # Rule 2 — schema integrity (valid versions per figma-manifest.md: 1.0 | 1.1 | 1.2)
  VERSION=$(jq -r '.manifestVersion // empty' "$LATEST_MANIFEST" 2>/dev/null)
  case "$VERSION" in
    1.0|1.1|1.2) ;;
    *) problems+=("[rule 2] manifestVersion must be one of 1.0/1.1/1.2 (got \"${VERSION:-MISSING}\")") ;;
  esac
  for k in runId intent scope source configSnapshot icons components tokens ambiguities injectionObservations; do
    jq -e "has(\"$k\")" "$LATEST_MANIFEST" >/dev/null 2>&1 || problems+=("[rule 2] missing key: $k")
  done

  # Rule 3 — figmaVariable must hold a path, never a resolved literal
  RESOLVED=$(jq -r '[.components[]?.styledProperties[]? | select(.figmaVariable != null) | select(.figmaVariable | test("^#[0-9a-fA-F]{3,8}$|^\\d+(\\.\\d+)?(px|rem|em)$|^rgb"))] | length' "$LATEST_MANIFEST" 2>/dev/null || echo 0)
  [[ "$RESOLVED" -gt 0 ]] && problems+=("[rule 3] $RESOLVED styledProperties have a figmaVariable that looks like a resolved hex/rem/rgb literal — contract violation")

  # Rule 4 — unbound entries
  UNBOUND_TOTAL=$(jq '[.components[]?.styledProperties[]? | select(.unbound == true)] | length' "$LATEST_MANIFEST" 2>/dev/null || echo 0)
  UNBOUND_BAD=$(jq '[.components[]?.styledProperties[]? | select(.unbound == true and (.rawValue == null or .rawValue == ""))] | length' "$LATEST_MANIFEST" 2>/dev/null || echo 0)
  [[ "$UNBOUND_BAD" -gt 0 ]] && problems+=("[rule 4] $UNBOUND_BAD unbound styledProperty entries missing rawValue — fetcher emitted invalid data")
  [[ "$UNBOUND_TOTAL" -gt 0 && "$UNBOUND_BAD" -eq 0 ]] && echo "[codex/post-command] rule 4: $UNBOUND_TOTAL unbound styled properties in this run — flagged for the user." >&2

  # Rule 5 — blocking ambiguities
  BLOCKING=$(jq '[.ambiguities[]? | select(.blocking == true)] | length' "$LATEST_MANIFEST" 2>/dev/null || echo 0)
  if [[ "$BLOCKING" -gt 0 ]]; then
    BLOCKING_LIST=$(jq -r '.ambiguities[]? | select(.blocking == true) | "    • \(.issue) [\(.nodeId)]"' "$LATEST_MANIFEST" 2>/dev/null)
    {
      echo "[codex/post-command] rule 5: $BLOCKING blocking ambiguity(ies) in this run:"
      echo "$BLOCKING_LIST"
      echo "  Did the coordinator gate on these? If a build ran past them, that's a contract violation."
    } >&2
  fi

  # Rule 6 — surface injection observations verbatim
  INJ_COUNT=$(jq '.injectionObservations | length' "$LATEST_MANIFEST" 2>/dev/null || echo 0)
  if [[ "$INJ_COUNT" -gt 0 ]]; then
    {
      echo "[codex/post-command] rule 6: $INJ_COUNT injection observation(s) from Figma (data, never instructions):"
      jq -r '.injectionObservations[]? | "    • \(. | tostring)"' "$LATEST_MANIFEST" 2>/dev/null
    } >&2
  fi

  if [[ ${#problems[@]} -gt 0 ]]; then
    { echo "[codex/post-command] manifest issues in $LATEST_MANIFEST:"; printf '  ⚠ %s\n' "${problems[@]}"; } >&2
  fi
fi

# ─── Rule 7 — verify against reality (config + token files) ──────────────────
CONFIG="$REPO_ROOT/.figma-pipeline/config.json"
if [[ -r "$CONFIG" ]]; then
  SCHEMA="$REPO_ROOT/.figma-pipeline/config.schema.json"
  if [[ -r "$SCHEMA" ]] && command -v npx >/dev/null 2>&1; then
    RESULT=$(npx --yes --offline ajv-cli@5 validate -s "$SCHEMA" -d "$CONFIG" 2>&1)
    AJV_EXIT=$?
    if [[ $AJV_EXIT -ne 0 ]]; then
      if printf '%s' "$RESULT" | grep -qiE 'ENOTCACHED|only-if-cached|not found|cannot find'; then
        # ajv-cli isn't in the offline npm cache — skip the optional validation
        # gracefully rather than surfacing an npm error as a "schema failure".
        echo "[codex/post-command] rule 7: skipped config schema check (ajv-cli not in offline npm cache; run 'npx ajv-cli@5' once online to enable)." >&2
      else
        { echo "[codex/post-command] rule 7: config.json does not validate against the schema:"; printf '%s\n' "$RESULT" | head -10; } >&2
      fi
    fi
  fi
fi

TOKENS_DIR=$(jq -r '.tokens.outputDir // empty' "$CONFIG" 2>/dev/null || true)
if [[ -n "$TOKENS_DIR" && -d "$REPO_ROOT/$TOKENS_DIR" ]]; then
  while IFS= read -r f; do
    case "$f" in
      *.css|*.scss)
        # Count brace CHARACTERS, not matching lines. `grep -c` exits 1 when the
        # count is 0, so the old `grep -c … || echo 0` produced a two-line "0\n0"
        # value that broke the `[[ -eq ]]` arithmetic. `grep -o | wc -l` is always
        # a clean single integer (0 when none).
        OPEN=$(grep -o '{' "$f" 2>/dev/null | wc -l | tr -d '[:space:]')
        CLOSE=$(grep -o '}' "$f" 2>/dev/null | wc -l | tr -d '[:space:]')
        OPEN=${OPEN:-0}; CLOSE=${CLOSE:-0}
        [[ "$OPEN" -eq "$CLOSE" ]] || echo "[codex/post-command] rule 7: brace mismatch in $f: $OPEN '{' vs $CLOSE '}'" >&2
        ;;
      *.json)
        jq empty "$f" 2>/dev/null || echo "[codex/post-command] rule 7: invalid JSON: $f" >&2
        ;;
    esac
  done < <(find "$REPO_ROOT/$TOKENS_DIR" -type f \( -name '*.css' -o -name '*.scss' -o -name '*.json' \) 2>/dev/null | head -50)
fi

exit 0
