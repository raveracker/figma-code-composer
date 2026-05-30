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

    # WHY this branch exists (the one valid reason): the Read/Edit/Write block
    # above is trivially bypassed via the shell — `cat .env`, `source .env`,
    # `curl --data @.env`, `... < .env` would all leak or clobber the secret
    # file. So Bash must be guarded too.
    #
    # But it must guard ACCESS, not MENTION. The old version flagged any `.env`
    # substring anywhere in the command, so writing a config file whose DATA
    # contains the strings ".env"/".env.*" (e.g. an allowlist emitted via a
    # heredoc) tripped it. Two-stage fix:
    #   (1) strip heredoc bodies — they are data being written, not file access;
    #   (2) on what remains, only flag a protected .env that sits in an actual
    #       access position: argument to a read/exfil verb, or a <,>,>>
    #       redirection target. A `.env` that is merely a quoted string literal
    #       (preceded by a quote, not whitespace) is data and is left alone.

    # (1) Drop heredoc bodies (`<<EOF ... EOF`, quoted or `<<-` indented forms).
    CMD="$(printf '%s\n' "$CMD" | awk '
      BEGIN { hd=0; delim="" }
      {
        if (hd) {
          t=$0; sub(/^[ \t]+/,"",t); sub(/[ \t]+$/,"",t)
          if (t==delim) hd=0
          next
        }
        if (match($0, /<<-?[ \t]*[\047\042]?[A-Za-z_][A-Za-z0-9_]*/)) {
          d=substr($0, RSTART, RLENGTH); gsub(/[^A-Za-z0-9_]/,"",d); delim=d; hd=1
        }
        print
      }')"

    # (2) Access-position detection.
    #   (a) read/exfil/copy/transmit verb whose argument is a protected .env, or
    #   (b) a <, > or >> redirection naming a protected .env.
    # The token must be preceded by whitespace or `@` (curl/scp style) — never a
    # quote — so quoted string-literal data does not match. `.env.example` is
    # filtered out at the end.
    VERBS='cat|tac|nl|head|tail|less|more|most|strings|xxd|od|hexdump|base32|base64|uuencode|grep|egrep|fgrep|rg|ag|ack|awk|gawk|sed|cut|tr|rev|fold|sort|uniq|wc|cksum|md5sum|shasum|sha1sum|sha256sum|cp|mv|ln|scp|rsync|install|dd|tee|cmp|diff|comm|paste|source|curl|wget|nc|ncat|netcat|socat|openssl|gpg|vi|vim|nano|emacs'
    # Each grep is greedy, so a match ENDS at the .env token it found (the last
    # one in that span). Reduce every match to just that trailing token, THEN
    # drop the allowed `.env.example` template. Filtering on the trailing token
    # (not the whole line) prevents smuggling a real secret past the filter on a
    # line that also names the template, e.g. `cat .env.example .env`.
    SPANS="$( {
        printf '%s\n' "$CMD" | grep -oiE "\b(${VERBS})\b[^|;&<>()]*[[:space:]@]\.env(\.[A-Za-z0-9_]+)?" 2>/dev/null
        printf '%s\n' "$CMD" | grep -oE "[<>]{1,2}[[:space:]]*\.env(\.[A-Za-z0-9_]+)?" 2>/dev/null
      } 2>/dev/null || true )"
    # Pull EVERY .env token that sits in file position (preceded by whitespace,
    # `@`, or a redirection op — never a quote, so a quoted search pattern like
    # `grep ".env" .env.example` is left alone), strip the leading delimiter,
    # then drop the allowed `.env.example` template. Extracting all tokens (not
    # just the trailing one) blocks both `cat .env.example .env` and the reverse.
    HITS="$(printf '%s\n' "$SPANS" | grep -oE '(^|[[:space:]@<>])\.env(\.[A-Za-z0-9_]+)?' 2>/dev/null | sed -E 's/^[^.]*//' | grep -vxE '\.env\.example' 2>/dev/null || true)"
    if [[ -n "$(printf '%s' "$HITS" | tr -d '[:space:]')" ]]; then
      printf '%s\nCommand referenced: %s\n' "$BLOCK_MSG" "$(printf '%s' "$HITS" | tr '\n' ' ' | sed -E 's/  */ /g')" >&2
      exit 2
    fi
    ;;
  *) exit 0 ;;
esac

exit 0
