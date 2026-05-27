---
description: Configure the figma-to-code orchestration scaffold in this project. Runs the wizard, writes .figma-pipeline/config.json, wires Figma MCP, sets up graphify, and emits the derived write allowlist.
argument-hint: "[--re-detect]"
---

# /init-figma-compose — figma-pipeline setup wizard

(Renamed from `/init` so it doesn't shadow Claude Code's built-in `/init`. Trigger phrases: `/init-figma-compose`, "set up figma-pipeline", "configure the pipeline", "run the figma wizard".)

Spawn the `wizard` agent (model: sonnet). Pass `$ARGUMENTS` verbatim so `--re-detect` is honoured.

The wizard:

1. **Project identity** — asks for project name + one-line description.
2. **Figma MCP connect (hard gate)** — verifies `.mcp.json` has a `figma` entry, drives `mcp__figma__authenticate` → user completes browser flow → `mcp__figma__complete_authentication`, then makes one cheap read (`mcp__figma__get_metadata`) to prove the connection is live. **Config.json is not written until this passes.** Result: every subsequent `/figma-build` (etc.) starts with a known-good MCP — no more "agent spins up, then fails on first tool call."
3. **Stack detection** — spawns `project-detector` to identify framework + CSS system + relevant paths. User confirms or overrides.
4. **Design system OR methodology** — design system first; if `none`, then design methodology (atomic / feature-sliced / component-based / flat).
5. **CSS choice** — Tailwind v4/v3 / UnoCSS / vanilla CSS vars / CSS Modules / Sass / vanilla-extract / Panda / styled-components — with examples and a guided migration plan when the detected system differs.
6. **Paths + stories + tests + output-structure** — derived per stack, with confirmation prompts.
7. **Tools** — Claude Code / Cursor / Codex CLI multi-select.
8. **Skills install/strip** — prunes canonical `.figma-pipeline/skills/` to the resolved install set and refreshes per-tool surfaces.
9. **RTK detection (optional)** — detects the external Rust binary that compresses shell-output tokens. If absent, prints the install command + per-tool init commands tailored to the AI tools you enabled (RTK is user-level only — no project-scoped install). The wizard never runs `brew install rtk` or `rtk init` itself. See `.claude/agents/wizard.md` § Step 7.6.
10. **Graphify registration** (post-wizard) — detects the external `graphify` CLI ([safishamsi/graphify](https://github.com/safishamsi/graphify), PyPI `graphifyy`). If present, registers `/graphify` as a project-scoped skill via `graphify install --project`. **Does not build the graph** — the user runs `/graphify .` in their assistant after the wizard exits. If absent, prints the install one-liner (`uv tool install graphifyy` / `pipx install graphifyy`). See `.claude/agents/wizard.md` § Step 7.7.
11. **Patch target `.gitignore`** — appends the scaffold-generated paths (`.figma-pipeline/config.json`, `graphify-out/`, `/tmp/figma-*/`) so consumers never accidentally commit local-only state. Idempotent.

Final output:

- `.figma-pipeline/config.json` — validated against `.figma-pipeline/config.schema.json`.
- `.mcp.json` — Figma MCP entry confirmed AND proven reachable.
- `.codex/config.json` — Codex CLI mirror (only when `tools.codexCli == true`).
- `.gitignore` — patched at the project root (idempotent).
- `graphify-out/` — **not** built by the wizard. Present only after the user types `/graphify .` in their assistant.
- Summary printed listing: project, framework + variant, CSS system, methodology, write allowlist, tools enabled, RTK status, graphify status.

The wizard NEVER writes outside the default allowlist (`.figma-pipeline/**`, `.mcp.json`, `.codex/**`, `/tmp/**`, `.gitignore`, `graphify-out/`). The post-wizard allowlist takes effect only after step 7 confirms.

Do not edit any other file. Do not commit. Do not push.
