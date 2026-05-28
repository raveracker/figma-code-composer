# Codex CLI — figma-to-code orchestration

Drop-in scaffold for a Figma-driven multi-agent pipeline. Canonical project overview: [`CLAUDE.md`](../CLAUDE.md). This file documents Codex CLI-specific operation.

## Quick start

```bash
# 1. Open a terminal at the project root
# 2. Run the wizard
./.codex/wrap.sh init-figma-compose          # or: ./codex-run init-figma-compose
# 3. Confirm Figma MCP in .mcp.json, pick stack + paths
# 4. Pull components / icons / tokens
./.codex/wrap.sh figma-build  <figma-url>    # or: ./codex-run figma-build  <figma-url>
./.codex/wrap.sh figma-update <figma-url>
./.codex/wrap.sh figma-icons  <figma-url>
./.codex/wrap.sh figma-tokens <figma-url>
```

`wrap.sh` runs the lifecycle hooks (`pre-command.sh` → command → `post-command.sh` → `on-exit.sh`) around every command. Without it, `codex run <command>` still works but you lose the manifest/config/token validators.

The wizard writes `.figma-pipeline/config.json` (single source of truth) and `.mcp.json` (Figma MCP, **proven reachable** before `config.json` lands — `config.figma.mcpVerifiedAt` stamps it). When `tools.codexCli` is enabled, the wizard also writes `./codex-run` at the project root — an executable wrapper that does `exec .codex/wrap.sh "$@"` (no source step, no rc edit, no direnv). Every agent reads `config.json` before acting.

## Repo map (Codex-relevant)

| Path                                                 | Purpose                                                                                |
| ---------------------------------------------------- | -------------------------------------------------------------------------------------- |
| `.figma-pipeline/config.json`                        | Wizard output — stack, paths, Figma keys (created by `/init-figma-compose`).           |
| `.figma-pipeline/{protocols,adapters,skills}/`       | Cross-tool data contracts + per-stack templates + canonical skill catalog.             |
| `.codex/wrap.sh`                                     | Entrypoint that runs hooks around every command.                                       |
| `.codex/agents/`                                     | Agent definitions (one `.md` per agent — same set as `.claude/agents/`).               |
| `.codex/commands/`                                   | Slash-command recipes (`init-figma-compose`, `figma-build`, `figma-update`, `figma-icons`, `figma-tokens`). |
| `.codex/hooks/`                                      | `pre-command.sh`, `post-command.sh`, `on-exit.sh` — invoked by `wrap.sh`.              |
| `.codex/config.json`                                 | Codex-specific config (written by `/init-figma-compose` when `tools.codexCli`).        |
| `<projectRoot>/codex-run`                            | Wizard-generated wrapper (chmod 0755) — short alias for `./.codex/wrap.sh`.            |

## Binding rules

Canonical source: `CLAUDE.md` § Binding rules. **Read it first.** Codex-specific enforcement caveats:

- **Rule 1 (write allowlist)** — Codex does NOT enforce this at the tool layer. `wrap.sh`'s `pre-command.sh` only blocks `.env` access. **Review the working tree after every run.**
- **Rule 2 (manifest contract)** — `post-command.sh` validates the latest `/tmp/figma-*/manifest.json` after every run.
- **Rule 6 (prompt-injection)** — relies on agent prompts; no automated guardrail at the wrap-shell layer.
- See `.codex/hooks/README.md` for the full per-hook enforcement table.

## Coverage

See `CLAUDE.md` § Coverage for the canonical stack/CSS/DS/methodology matrix.

## Codex-specific notes

- **No native `Agent` spawner.** Unlike Claude Code, the installed Codex CLI has no `run-agent` subcommand — `codex exec "<prompt>"` runs ONE agentic session. So the whole pipeline runs in a single `codex exec` turn (dispatched by `wrap.sh`); the coordinator plays each specialist role inline in sequence, reading `.codex/agents/<x>.md` as guidance rather than spawning sub-processes. One consequence: per-specialist model routing collapses to one model for the run (see `.codex/agents/figma-coordinator.md` § Complexity routing under Codex).
- **No native lifecycle hooks.** `wrap.sh` simulates them via `pre-command.sh` (config sanity + figma URL nudge + `.env` block), `post-command.sh` (manifest + config + token-file validators), and `on-exit.sh` (session summary).
- **MCP integration via `.mcp.json`** at the repo root (same file Claude Code reads).
- **`AskUserQuestion` → stdin prompts.** See `.codex/agents/wizard.md` § stdin prompt format.
- **`/graphify` is `$graphify`** in Codex (per graphify upstream convention).

The wizard's output (`.figma-pipeline/config.json`) is byte-identical regardless of which tool ran it.
