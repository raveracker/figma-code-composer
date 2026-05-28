# `codex run init-figma-compose` — Codex CLI wizard

(Renamed from `init`; the wrapper still resolves `.codex/wrap.sh init-figma-compose`.)

**Before running this:** complete `README § Prerequisites` for Codex CLI — at minimum run `codex` → `/plugins` → search Figma to install the Figma MCP plugin. Optionally also install Graphify (`uv tool install graphifyy`) and RTK (`brew install rtk && rtk init -g --codex`). The wizard verifies these; it does not install them.

Dispatch to `.codex/agents/wizard.md`. Pass `$ARGUMENTS` verbatim.

The agent:

1. Asks the user (via stdin) for project name + description.
2. **Figma MCP verify (hard gate)** — probes both namespaces (`mcp__figma__get_metadata` and `mcp__plugin_figma_figma__get_metadata`). On both unknown → exit 3 with pointer to `README § Prerequisites § Required — Figma MCP` for Codex. On auth required → ask user to confirm sign-in in Codex's plugin UI, then re-probe. Records `config.figma.mcpToolNamespace` with the working prefix. **Config.json is not written until this passes.**
3. Runs the project-detector logic inline (Codex doesn't have a native sub-agent spawner; `.codex/agents/project-detector.md` is the included system prompt for a separate model call).
4. Asks for methodology + CSS-system choice via stdin.
5. Derives paths from detector + user confirmation.
6. Writes `.figma-pipeline/config.json` (no auto-create of `.mcp.json` — Prerequisites owns that).
7. Validates against `.figma-pipeline/config.schema.json` using `npx -y ajv-cli validate` if available.
8. **Graphify verify + project-skill registration (optional)** — detects `graphify` on PATH. If present, runs `graphify install --project --platform codex` to register the `$graphify` skill in this repo (project-scoped — writes inside repo). Does NOT build the graph — the user runs `$graphify .` in Codex after the wizard exits. If absent, prints a pointer to `README § Prerequisites § Optional — Graphify`. Always appends `graphify-out/` + scaffold paths to the target's `.gitignore`. (Codex uses `$graphify` instead of `/graphify` per the graphify README.)
9. **Codex `./codex-run` shortcut** — writes an executable `<projectRoot>/codex-run` (chmod 0755) that wraps `.codex/wrap.sh`. User invokes `./codex-run figma-build <url>` — no source, no rc edit, no direnv. Project-local, team-portable (safe to commit).

Exit codes:

- `0` — wizard completed and config validates
- `1` — user aborted
- `2` — validation failed (config exists at `.figma-pipeline/config.json` but invalid; details to stderr)
- `3` — Figma MCP unavailable (no config written)
- `4` — graphify CLI registration failed (config written, skill not installed; user can retry manually)
