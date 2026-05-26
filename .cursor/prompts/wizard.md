# Cursor wizard prompt — `/init` mirror

When the user types `/init` (or asks to "set up figma-pipeline" / "configure the pipeline" / "run the wizard"), follow the protocol below — it is the Cursor mirror of `.claude/agents/wizard.md`.

Read these first:

- `.figma-pipeline/config.schema.json` — binding contract for the output
- `.figma-pipeline/protocols/figma-manifest.md`
- `.figma-pipeline/protocols/token-strategy.md`
- `.figma-pipeline/protocols/component-layout.md`
- `.figma-pipeline/protocols/allowlist.md`

## Protocol (same as `.claude/agents/wizard.md`)

Steps:

1. **Pre-flight** — handle existing `.figma-pipeline/config.json`: ask overwrite vs incremental vs abort.
2. **Project identity** — ask for `name` + `description`.
3. **Figma MCP connect** — verify `.mcp.json` has a `figma` entry. In Cursor, the user manages MCP servers via their global settings; instruct them to enable the Figma server if missing and continue when they confirm. (Cursor does not expose programmatic auth like Claude Code.)
4. **Stack detection** — invoke the `project-detector` workflow inline: run the `Glob`/`Read`/`Grep` checks listed in `.claude/agents/project-detector.md` § Detection rules, then confirm with the user.
5. **Methodology + CSS choice** — present the options from `.claude/agents/wizard.md` § Step 4.
6. **Derive paths** — ask the user to confirm or override the path defaults.
7. **Tools** — multi-select; toggle `tools.claudeCode` / `tools.cursor` / `tools.codexCli`.
8. **Compose + validate** — write `.figma-pipeline/config.json`; validate against the schema (use `npx ajv-cli validate` if available; else structural check).
9. **Report** — print the summary block from `.claude/agents/wizard.md` § Step 8.

## Write scope

Cursor in agent mode may write only:

- `.figma-pipeline/config.json`
- `.mcp.json` (merge `figma` only)
- `.codex/config.json` (when codexCli is enabled)
- `/tmp/figma-wizard-*` (scratch)

Any other write → stop and tell the user. The Cursor rule `.cursor/rules/frozen-paths.mdc` enforces this in agent mode.

## Differences from Claude Code

- No `AskUserQuestion` tool — present each question as a normal chat prompt, wait for an explicit answer, and confirm before moving on.
- No `Agent` tool to spawn `project-detector` as a sub-agent — inline its detection logic.
- MCP auth is user-driven via Cursor settings — guide the user, don't try to call `mcp__figma__authenticate`.

The output (`.figma-pipeline/config.json`) MUST be byte-identical regardless of which tool ran the wizard.
