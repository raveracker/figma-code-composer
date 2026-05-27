# Codex figma-coordinator

Mirror of `.claude/agents/figma-coordinator.md`. Codex variant substitutions:

| Claude Code                              | Codex CLI                                                                  |
| ---------------------------------------- | -------------------------------------------------------------------------- |
| `Agent(subagent_type=figma-fetcher)`     | `codex run-agent figma-fetcher --model <id> --input /tmp/figma-<runId>/in.json` |
| `Agent(subagent_type=token-builder)`     | `codex run-agent token-builder --model <id> --input ...`                   |
| `Agent(subagent_type=component-builder)` | `codex run-agent component-builder --model <id> --input ...`               |
| `Agent(subagent_type=icon-generator)`    | `codex run-agent icon-generator --model <id> --input ...`                  |
| `Agent(subagent_type=story-author)`      | `codex run-agent story-author --model <id> --input ...`                    |
| `Agent(subagent_type=test-author)`       | `codex run-agent test-author --model <id> --input ...`                     |

Protocol, write scope, error handling, and report format are otherwise byte-identical. See `.claude/agents/figma-coordinator.md`.

## Complexity routing — Codex model mapping

The Claude coordinator's routing table resolves to an abstract size (`sm` / `md` / `lg`) per tier. Codex maps as follows (defaults from `config.codex.modelMap`, see `.figma-pipeline/protocols/complexity.md` § Per-tool size → model mapping):

| Tier      | Abstract size | Codex model (default)   | 2nd-pass review |
| --------- | ------------- | ----------------------- | --------------- |
| trivial   | `sm`          | `gpt-4o-mini`           | no              |
| moderate  | `md`          | `gpt-4o`                | no              |
| complex   | `lg`          | `o3`                    | no              |
| extreme   | `lg`          | `o3`                    | yes (`lg`)      |

Override via `config.codex.modelMap.<sm|md|lg>` (any OpenAI model ID your Codex CLI version supports). The coordinator MUST pass `--model <id>` on every `codex run-agent` invocation — without it, Codex uses the global default from `~/.codex/config.toml`, which defeats the complexity routing.

### Older Codex CLI versions

The `--model` flag is the modern form. If `codex --version` reports older than the model flag was added, fall back to `-m <id>`. If neither is supported, log a warning to `/tmp/figma-<runId>/lessons.md` (`"codex CLI <version> does not expose per-call model selection — tier routing is skill-set-only on this version"`) and dispatch without a model arg.

### Verifying the routing is wired

To sanity-check on a real run, after `codex run-agent` returns, scan its log for the resolved model line. If it's missing, `wrap.sh`'s `post-command.sh` should flag it (see `.codex/hooks/post-command.sh` — extend if needed).

## KG / handover CLI calls

These work identically under Codex because they're plain shell — `npx fcc kg:query`, `npx fcc kg:stage`, `npx fcc kg:merge`, `npx fcc handover` all run via Bash from inside `codex run-agent`. No Codex-specific wiring needed; same exit codes apply.
