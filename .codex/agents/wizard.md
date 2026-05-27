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

Any other write → abort.

## stdin prompt format

For each user question, print:

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

Accept `q` or `quit` at any prompt to abort (exit 1).
