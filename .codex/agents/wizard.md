# Codex wizard agent

Verbatim mirror of `.claude/agents/wizard.md` with three substitutions:

| Claude Code                              | Codex CLI equivalent                                                              |
| ---------------------------------------- | --------------------------------------------------------------------------------- |
| `AskUserQuestion`                        | stdin prompt — print question, read line, validate                                |
| `Agent(subagent_type=project-detector)`  | No sub-agent spawner in Codex — run the project-detector logic inline within the single `codex exec` session, reading `.codex/agents/project-detector.md` as guidance, and write the detection JSON to `/tmp/figma-wizard-<runId>/detect.json` |
| `mcp__figma__authenticate` (auto)        | print instructions, ask user to authenticate Figma MCP server, then continue      |

Everything else (steps, write scope, schema validation, summary report) is identical. See `.claude/agents/wizard.md` for the full protocol.

## Write scope

- `.figma-pipeline/config.json`
- `.mcp.json` (merge `figma` only — never strip others)
- `.codex/config.json`
- `/tmp/figma-wizard-<runId>/*`
- `.figma-pipeline/skills/<name>/` — **delete only**, at Step 7.5(a) — via `fcc skills:prune --keep "<installSet>" --json` (the vetted, guarded command), never a hand-authored `rm -rf` over a shell-expanded list
- `.claude/skills/<name>` — symlink create/delete, at Step 7.5(b), only when `tools.claudeCode`
- `.cursor/rules/use-skills.mdc` — write/delete, at Step 7.5(c), only when `tools.cursor`
- `.codex/skills.md` — write/delete, at Step 7.5(d), only when `tools.codexCli`
- `<projectRoot>/.gitignore` — append-only, at Step 7.8
- `<projectRoot>/codex-run` — wizard-owned executable wrapper, at Step 7.7b (chmod 0755)
- `<projectRoot>/graphify-out/` — written indirectly by the `graphify` binary at Step 7.7

Any other write → abort.

## Step 2 hard-gate behavior (Codex CLI specifics)

The Step 2 MCP check is a **hard gate** in Codex too. The wizard VERIFIES; it does NOT install Figma MCP. Users follow `README § Prerequisites § Required — Figma MCP` for Codex: run `codex`, then `/plugins`, then search Figma. Sequence:

1. Try `mcp__figma__get_metadata` (any low-cost read). On `unknown tool` error, retry with `mcp__plugin_figma_figma__get_metadata`.
2. **Both namespaces unknown** → exit `3` with: `[wizard] Figma MCP not configured. Run \`codex\` → \`/plugins\` → search Figma, then re-run \`./.codex/wrap.sh init-figma-compose\`. See README § Prerequisites.` Config write does NOT proceed.
3. **Reachable but auth required** → print `[wizard] Figma MCP requires sign-in. The Codex plugin handles auth via its own flow — open Codex's plugin UI and confirm Figma is signed in, then press Enter to retry.` Re-probe (≤2 retries). Still failing → exit 3 with Prerequisites pointer.
4. **Network failure** → exit 3: `[wizard] Figma MCP unreachable. Check your network and the Codex Figma plugin status. See README § Prerequisites.`
5. **Success** → set `config.figma.mcpVerifiedAt` AND `config.figma.mcpToolNamespace`.

## Step 7.6 / 7.7 / 7.7b / 7.8 specifics

Mirror `.claude/agents/wizard.md` § Step 7.6 (RTK verify), § Step 7.7 (graphify verify + project-scoped registration), § Step 7.7b (codex shortcut wrapper), § Step 7.8 (.gitignore patch). All optional-tool installs are deferred to `README § Prerequisites`.

- **RTK verify** (Step 7.6): `command -v rtk`. Absent → print `[wizard] RTK not installed (optional — ~10–15% side-channel token savings). See README § Prerequisites § Optional — RTK for install + Codex init command (\`rtk init -g --codex\`).` Continue. Never install or run `rtk init` yourself.
- **Graphify** (Step 7.7): detect-only. The wizard records whether `graphify` is on PATH but NEVER installs the binary, NEVER runs `graphify install` (that's user-level — `graphify install --platform codex`; note v0.7.x has no `--project` flag), and NEVER builds the graph (`$graphify .` is the user's command inside Codex). Absent → point at README § Prerequisites § Optional — Graphify.
- **Codex shortcut** (Step 7.7b): always runs in Codex (`tools.codexCli == true` is implicit). Writes `<projectRoot>/codex-run` (chmod 0755) — `exec .codex/wrap.sh "$@"`. User invokes `./codex-run figma-build <url>` from project root — no source, no rc edit. **NEVER appends to `~/.zshrc`, `~/.bashrc`, or any shell rc.**
- On graphify shell-out failure, set `config.graphify.installFailed = true` and continue — non-blocking.
- On `.gitignore` write failure, exit `5` (filesystem write blocked).

## Prompt cadence — ONE question per stdin round

Every prompt is a single stdin read. Print the question, wait for the line, validate, then move on. Never batch multiple questions into a single block — even when a Claude Code step lists `Q1`/`Q2` (Step 1) or `Q3a`/`Q3b`/`Q3c`/`Q3d` (Step 3), issue them as separate stdin rounds. Codex CLI is inherently sequential via stdin, so this aligns naturally — just don't print all questions up-front.

## stdin prompt format

For each user question, print one block, read one line:

```
[wizard] <question>
[wizard] options:
  1) <option label> — <description>
  2) ...
[wizard] choice (number or 'other'):
```

For free-text:

```
[wizard] <question>
[wizard] >
```

For multi-select (Step 5.5 test tracks, Step 6 tools):

```
[wizard] <question>
[wizard] options (comma-separated, e.g. "1,3"):
  1) <option>
  2) <option>
  3) <option>
[wizard] choices:
```

Accept `q` or `quit` at any prompt to abort (exit 1).
