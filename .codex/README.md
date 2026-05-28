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

## Two ways to run: wrapper (nested) vs. inline

`./codex-run` / `./.codex/wrap.sh` shell out to a **nested `codex exec`**. That's the right entry from a **plain terminal, a script, or CI** — the hooks fire automatically around the run. But a nested `codex exec` **cannot start inside an already-running Codex session**: the parent sandbox blocks the child's app-server with `failed to initialize in-process app-server client: Operation not permitted (os error 1)`. `wrap.sh` detects this (the session exports `CODEX_SANDBOX`) and refuses early rather than dumping that raw error.

So when you are **inside an interactive `codex` session**, run the pipeline **inline** instead — the current session already holds the Figma MCP tools, so there is nothing to nest (this mirrors how Cursor runs the pipeline: one thread, no spawner). Ask Codex to follow the recipe directly, e.g.:

> Run figma-build **inline** for `https://www.figma.com/design/…?node-id=…`. Follow `.codex/commands/figma-build.md` → `.codex/agents/figma-coordinator.md` in THIS session. Do NOT call `./codex-run` or `codex exec` — no nesting.

Codex then plays coordinator → fetcher → token/icon/component builders → stories/tests inline, sequentially, exactly as the wrapper's nested session would. Swap the recipe name for `figma-update` / `figma-icons` / `figma-tokens` as needed.

### Inline ≠ no validation — run the hook checks yourself

The lifecycle hooks only fire automatically under `wrap.sh`. Inline, keep the same guardrails by hand:

- **Before:** confirm `.figma-pipeline/config.json` exists and `config.figma.mcpVerifiedAt` is stamped (the coordinator pre-flight already does this) — and that the live MCP probe (fetcher's first action) succeeds.
- **After:** run `.codex/hooks/post-command.sh figma-build` once — it validates the manifest you just produced (rules 2–6), the config schema (rule 7), and token-file syntax.

### Which entry should I use?

| You are…                                  | Use                                                                  |
| ----------------------------------------- | ------------------------------------------------------------------- |
| Plain terminal / script / CI              | `./codex-run figma-build '<url>'` — nested `codex exec`; hooks auto-fire |
| Inside an interactive `codex` session     | The **inline** recipe above — no nesting; run the post-command hook by hand |

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

Canonical source: `.figma-pipeline/PIPELINE.md` § Binding rules (imported by `CLAUDE.md`). **Read it first.** Codex-specific enforcement caveats:

- **Rule 1 (write allowlist)** — Codex does NOT enforce this at the tool layer. `wrap.sh`'s `pre-command.sh` only blocks `.env` access. **Review the working tree after every run.**
- **Rule 2 (manifest contract)** — `post-command.sh` validates the latest `/tmp/figma-*/manifest.json` after every run.
- **Rule 6 (prompt-injection)** — relies on agent prompts; no automated guardrail at the wrap-shell layer.
- See `.codex/hooks/README.md` for the full per-hook enforcement table.

## Coverage

See `CLAUDE.md` § Coverage for the canonical stack/CSS/DS/methodology matrix.

## Codex-specific notes

- **No native `Agent` spawner.** Unlike Claude Code, the installed Codex CLI has no `run-agent` subcommand — `codex exec "<prompt>"` runs ONE agentic session. So the whole pipeline runs in a single agentic turn — either the nested `codex exec` dispatched by `wrap.sh`, or the current interactive session running the recipe inline (see § _Two ways to run_) — and the coordinator plays each specialist role in sequence, reading `.codex/agents/<x>.md` as guidance rather than spawning sub-processes. One consequence: per-specialist model routing collapses to one model for the run (see `.codex/agents/figma-coordinator.md` § Complexity routing under Codex).
- **No native lifecycle hooks.** `wrap.sh` simulates them via `pre-command.sh` (config sanity + figma URL nudge + `.env` block), `post-command.sh` (manifest + config + token-file validators), and `on-exit.sh` (session summary).
- **MCP integration via `.mcp.json`** at the repo root (same file Claude Code reads).
- **`AskUserQuestion` → stdin prompts.** See `.codex/agents/wizard.md` § stdin prompt format.
- **`/graphify` is `$graphify`** in Codex (per graphify upstream convention).

The wizard's output (`.figma-pipeline/config.json`) is byte-identical regardless of which tool ran it.
