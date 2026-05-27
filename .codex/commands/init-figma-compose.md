# `codex run init-figma-compose` — Codex CLI wizard

(Renamed from `init`; the wrapper still resolves `.codex/wrap.sh init-figma-compose`.)

Dispatch to `.codex/agents/wizard.md`. Pass `$ARGUMENTS` verbatim.

The agent:

1. Asks the user (via stdin) for project name + description.
2. **Figma MCP gate** — reads `.mcp.json`; if no `figma` server, writes the standard entry and asks the user to confirm the browser auth flow. Then makes one cheap MCP read (`get_metadata`) to prove the connection. **Config.json is not written until this passes.** Exit code 3 if unreachable.
3. Runs the project-detector logic inline (Codex doesn't have a native sub-agent spawner; `.codex/agents/project-detector.md` is the included system prompt for a separate model call).
4. Asks for methodology + CSS-system choice via stdin.
5. Derives paths from detector + user confirmation.
6. Writes `.figma-pipeline/config.json` and (when applicable) updates `.mcp.json`.
7. Validates against `.figma-pipeline/config.schema.json` using `npx -y ajv-cli validate` if available.
8. **Graphify registration** — detects the external `graphify` CLI. If present, runs `graphify install --project --platform codex` to register the `$graphify` skill in this repo. Does NOT build the graph — the user runs `$graphify .` in Codex after the wizard exits. If absent, prints `uv tool install graphifyy` and continues. Always appends `graphify-out/` + scaffold paths to the target's `.gitignore`. See `.codex/agents/wizard.md` § Step 7.7. (Codex uses `$graphify` instead of `/graphify` per the graphify README.)
9. **Codex `./codex-run` shortcut** — writes an executable `<projectRoot>/codex-run` (chmod 0755) that wraps `.codex/wrap.sh`. User invokes `./codex-run figma-build <url>` — no source, no rc edit, no direnv. Project-local, team-portable (safe to commit). See `.codex/agents/wizard.md` § Step 7.7b.

Exit codes:

- `0` — wizard completed and config validates
- `1` — user aborted
- `2` — validation failed (config exists at `.figma-pipeline/config.json` but invalid; details to stderr)
- `3` — Figma MCP unavailable (no config written)
- `4` — graphify CLI registration failed (config written, skill not installed; user can retry manually)
