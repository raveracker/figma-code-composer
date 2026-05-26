# `codex run init` — Codex CLI wizard

Dispatch to `.codex/agents/wizard.md`. Pass `$ARGUMENTS` verbatim.

The agent:

1. Asks the user (via stdin) for project name + description.
2. Reads `.mcp.json`; if no `figma` server, prompts the user to add one and exits with instructions.
3. Runs the project-detector logic inline (Codex doesn't have a native sub-agent spawner; `.codex/agents/project-detector.md` is the included system prompt for a separate model call).
4. Asks for methodology + CSS-system choice via stdin.
5. Derives paths from detector + user confirmation.
6. Writes `.figma-pipeline/config.json` and (when applicable) updates `.mcp.json`.
7. Validates against `.figma-pipeline/config.schema.json` using `npx -y ajv-cli validate` if available.

Exit codes:

- `0` — wizard completed and config validates
- `1` — user aborted
- `2` — validation failed (config exists at `.figma-pipeline/config.json` but invalid; details to stderr)
- `3` — Figma MCP unavailable
