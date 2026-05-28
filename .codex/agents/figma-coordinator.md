# Codex figma-coordinator

Mirror of `.claude/agents/figma-coordinator.md` — same protocol, write scope, error handling, report format, and the Step-0 MCP probe. See that file for the full pipeline.

## Codex has no sub-agent spawner — it's ONE `codex exec` session

This is the load-bearing difference from Claude Code. Claude Code's coordinator spawns each specialist as a separate `Agent(subagent_type=…)` process with its own context + model. **The installed Codex CLI has no equivalent** — `codex exec "<prompt>"` runs a single agentic session. (Earlier scaffold versions assumed a `codex run-agent <name>` subcommand; no released Codex CLI provides it.)

So under Codex, the WHOLE pipeline runs inside one `codex exec` turn dispatched by `.codex/wrap.sh`. The coordinator does not spawn specialists — it **plays each specialist role itself, in sequence, reading that role's `.codex/agents/<name>.md` as inline guidance**:

| Claude Code                              | Codex CLI (single session)                                                       |
| ---------------------------------------- | -------------------------------------------------------------------------------- |
| `Agent(subagent_type=figma-fetcher)`     | Read `.codex/agents/figma-fetcher.md`; perform the fetch inline → write `/tmp/figma-<runId>/manifest.json` |
| `Agent(subagent_type=token-builder)`     | Read `.codex/agents/token-builder.md`; emit tokens inline                        |
| `Agent(subagent_type=component-builder)` | Read `.codex/agents/component-builder.md`; write components inline               |
| `Agent(subagent_type=icon-generator)`    | Read `.codex/agents/icon-generator.md`; write icons inline                       |
| `Agent(subagent_type=story-author)`      | Read `.codex/agents/story-author.md`; write stories inline                       |
| `Agent(subagent_type=test-author)`       | Read `.codex/agents/test-author.md`; write tests inline                          |

The DAG order still holds (fetch → tokens → icons + components → stories + tests), but it's sequential within one context rather than parallel processes. Single-writer KG discipline still applies — stage each role's ledger entry as you complete it, merge once at the end.

## Complexity routing under Codex

Because everything runs in one `codex exec` session, **there is no per-specialist model**. The Claude Code routing (haiku fetcher, opus component-builder, etc.) collapses to **one model for the whole run** under Codex — whatever model the session uses.

- Set it via `codex exec --model <id>` if your Codex CLI supports the flag (check `codex exec --help`); otherwise the session uses the global default in `~/.codex/config.toml`.
- Resolve `<id>` from `config.codex.modelMap.<size>` where `<size>` is the tier's abstract size (trivial→`sm`, moderate→`md`, complex/extreme→`lg`). Defaults: `sm=gpt-4o-mini`, `md=gpt-4o`, `lg=o3`.
- The complexity tier still controls the **skill set** (which `.codex/agents/<name>.md` roles load which skills) and whether a final `code-reviewer` pass runs (extreme tier) — that part works the same. Only the per-specialist model split is lost.

If your Codex CLI exposes no model flag at all, log a note to `/tmp/figma-<runId>/lessons.md` and proceed with the global default — tier routing degrades to skill-set-only.

## KG / handover CLI calls

Identical to Claude Code — `npx fcc kg:query`, `kg:stage`, `kg:merge`, `kg:verify`, `handover`, `complexity` all run via Bash from inside the `codex exec` session. Same flags, same exit codes. (All implemented as of fcc v0.1.0 — see `.figma-pipeline/protocols/cli.md`.) The Step-0 MCP probe and the handover-file-exists check from the Claude coordinator apply here too.
