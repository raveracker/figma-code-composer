# Codex wizard agent

Verbatim mirror of `.claude/agents/wizard.md` with three substitutions:

| Claude Code                              | Codex CLI equivalent                                                              |
| ---------------------------------------- | --------------------------------------------------------------------------------- |
| `AskUserQuestion`                        | stdin prompt — print question, read line, validate                                |
| `Agent(subagent_type=project-detector)`  | `codex run-agent project-detector --output /tmp/figma-wizard-<runId>/detect.json` |
| `mcp__figma__authenticate` (auto)        | print instructions, ask user to authenticate Figma MCP server, then continue      |

Everything else (steps, write scope, schema validation, summary report) is identical. See `.claude/agents/wizard.md` for the full protocol.

## Write scope

- `.figma-pipeline/config.json`
- `.mcp.json` (merge `figma` only — never strip others)
- `.codex/config.json`
- `/tmp/figma-wizard-<runId>/*`
- `.figma-pipeline/skills/<name>/` — **delete only**, at Step 7.5(a) (canonical prune)
- `.claude/skills/<name>` — symlink create/delete, at Step 7.5(b), only when `tools.claudeCode`
- `.cursor/rules/use-skills.mdc` — write/delete, at Step 7.5(c), only when `tools.cursor`
- `.codex/skills.md` — write/delete, at Step 7.5(d), only when `tools.codexCli`
- `<projectRoot>/.gitignore` — append-only, at Step 7.8
- `<projectRoot>/codex-run` — wizard-owned executable wrapper, at Step 7.7b (chmod 0755)
- `<projectRoot>/graphify-out/` — written indirectly by the `graphify` binary at Step 7.7

Any other write → abort.

## Step 2 hard-gate behavior (Codex CLI specifics)

The Step 2 MCP check is a **hard gate** in Codex too. Sequence:

1. Read `.mcp.json` (create with the `figma` entry if absent — never strip others).
2. Print: `[wizard] Step 2 — Figma MCP connect. Codex CLI cannot drive the browser auth flow; please open https://mcp.figma.com/mcp in your browser and sign in. Press Enter when done.`
3. Run a low-cost MCP read via the user's normal Codex MCP integration. If it fails, retry once, then exit `3` (Figma MCP unavailable) without writing `config.json`.
4. On success, set `config.figma.mcpVerifiedAt`.

## Step 7.6 / 7.7 / 7.7b / 7.8 specifics

Mirror `.claude/agents/wizard.md` § Step 7.6 (RTK detection — Codex init command is `rtk init -g --codex`), § Step 7.7 (graphify project-scoped skill registration via `graphify install --project --platform codex`), § Step 7.7b (codex shortcut wrapper), and § Step 7.8 (.gitignore patch).

- RTK detection: `command -v rtk`. If absent, print install + Codex-tailored init: `brew install rtk` (or curl/cargo) + `rtk init -g --codex`. Never run either yourself — RTK modifies user-level config.
- The wizard NEVER runs `graphify install` without `--project` and NEVER builds the graph itself — the user invokes `$graphify .` in Codex after the wizard exits.
- Step 7.7b always runs in Codex (since `tools.codexCli == true` is implicit for the Codex wizard). Writes `<projectRoot>/codex-run` (executable wrapper around `.codex/wrap.sh`) and chmods it to 0755. User invokes `./codex-run figma-build <url>` from the project root — no source, no rc edit. **NEVER appends to `~/.zshrc`, `~/.bashrc`, or any shell rc** — the wrapper is project-local on purpose.
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
