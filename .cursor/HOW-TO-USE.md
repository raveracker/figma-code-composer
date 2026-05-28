# Cursor — figma-to-code orchestration

Drop-in scaffold for a Figma-driven multi-agent pipeline. Canonical project overview: [`CLAUDE.md`](../CLAUDE.md). This file documents Cursor-specific operation.

## Quick start

```bash
# 1. Open the project in Cursor
# 2. Run the wizard from Cursor agent chat
/init-figma-compose                  # or "configure the figma-pipeline" / "run the wizard"
# 3. Confirm Figma MCP in Cursor's Settings → MCP, pick stack + paths
# 4. Pull components / icons / tokens
/figma-build  <figma-url>
/figma-update <figma-url>
/figma-icons  <figma-url>
/figma-tokens <figma-url>
```

The wizard writes `.figma-pipeline/config.json` (single source of truth) and `.mcp.json` — proven reachable via a low-cost MCP read before `config.json` lands (Cursor users enable Figma MCP in Settings → MCP first). Also patches the project root `.gitignore` (idempotent). Graphify is detect-only — if `graphify` is on PATH the wizard records it; you register the skill yourself with `graphify install --platform cursor` (see README § Prerequisites). Every agent reads `config.json` before acting.

## Repo map (Cursor-relevant only)

| Path                                  | Purpose                                                                                  |
| ------------------------------------- | ---------------------------------------------------------------------------------------- |
| `.figma-pipeline/config.json`         | Wizard output — stack, paths, Figma keys (created by `/init-figma-compose`).             |
| `.figma-pipeline/{protocols,adapters,skills}/` | Cross-tool data contracts + per-stack templates + canonical skill catalog.      |
| `.cursor/rules/`                      | Always-on rules — write allowlist, env block, manifest contract, config schema, figma URL nudge, per-agent roles. |
| `.cursor/prompts/`                    | Agent prompts (one per `.claude/agents/<x>.md`).                                         |
| `.cursor/prompts/commands/`           | Slash-command prompts (`init-figma-compose`, `figma-build`, `figma-update`, `figma-icons`, `figma-tokens`). |
| `.cursor/settings.json` + `mcp.json`  | Cursor project settings + MCP server entries (Figma + Storybook).                        |
| `.claude/` + `.codex/`                | Read-only mirrors of the same agents/commands.                                           |

## Binding rules

Canonical source: `.figma-pipeline/PIPELINE.md` § Binding rules (imported by `CLAUDE.md`). **Read it first.** Cursor-specific enforcement:

- `.cursor/rules/frozen-paths.mdc` (`alwaysApply: true`) enforces the write allowlist. Cursor cannot read shell env — bypass overrides must be explicit in chat.
- `.cursor/rules/manifest-contract.mdc` auto-attaches when editing `/tmp/figma-*/**`.
- `.cursor/rules/env-access.mdc` enforces `.env` lockout (only `.env.example` accessible).
- Per-rule details + global index: `.cursor/rules/README.md`.

## Coverage

See `CLAUDE.md` § Coverage for the canonical stack/CSS/DS/methodology matrix.

## Cursor-specific notes

- **No native sub-agent spawner.** When a Claude Code agent says `Agent(subagent_type=X)`, run agent X inline in the current chat thread by loading `.cursor/prompts/<x>.md`.
- **No lifecycle hooks.** `.cursor/rules/*.mdc` (`alwaysApply: true` for the critical ones) substitute. The Claude Code `.claude/hooks/*.sh` scripts do not run in Cursor.
- **MCP auth is manual.** Verify Figma MCP in Settings → MCP before running the wizard — the wizard hard-gates on a successful read.
- **Model preference is plan-aware and never forced.** Free plan: selection is locked to **Auto** — leave it; the pipeline runs on Auto. Paid plan: prefer **Composer 2.5** (Settings → Models), fall back to a **Claude model** for `lg`-size (complex/extreme) runs. The coordinator never overrides your selection — see `.cursor/rules/model-preference.mdc`.
- **`AskUserQuestion` → plain chat.** Where Claude Code uses the tool, Cursor asks the question as normal chat.

The wizard's output (`.figma-pipeline/config.json`) is byte-identical regardless of which tool ran it.
