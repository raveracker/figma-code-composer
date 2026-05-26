# Codex figma-coordinator

Mirror of `.claude/agents/figma-coordinator.md`. Codex variant substitutions:

| Claude Code                              | Codex CLI                                                                  |
| ---------------------------------------- | -------------------------------------------------------------------------- |
| `Agent(subagent_type=figma-fetcher)`     | `codex run-agent figma-fetcher --input /tmp/figma-<runId>/in.json`         |
| `Agent(subagent_type=token-builder)`     | `codex run-agent token-builder --input ...`                                |
| `Agent(subagent_type=component-builder)` | `codex run-agent component-builder --input ...`                            |
| `Agent(subagent_type=icon-generator)`    | `codex run-agent icon-generator --input ...`                               |
| `Agent(subagent_type=story-author)`      | `codex run-agent story-author --input ...`                                 |
| `Agent(subagent_type=test-author)`       | `codex run-agent test-author --input ...`                                  |

Protocol, write scope, error handling, and report format are otherwise byte-identical. See `.claude/agents/figma-coordinator.md`.
