---
description: Configure the figma-to-code orchestration scaffold in this project. Runs the wizard, writes .figma-pipeline/config.json, verifies Figma MCP, optionally registers /graphify, and emits the derived write allowlist.
argument-hint: "[--re-detect]"
---

# /init-figma-compose — figma-pipeline setup wizard

(Renamed from `/init` so it doesn't shadow Claude Code's built-in `/init`. Trigger phrases: `/init-figma-compose`, "set up figma-pipeline", "configure the pipeline", "run the figma wizard".)

**Before running this:** complete `README § Prerequisites` for your tool — at minimum the required Figma MCP setup, optionally Graphify and RTK. The wizard verifies these; it does not install them.

Spawn the `wizard` agent (model: sonnet). Pass `$ARGUMENTS` verbatim so `--re-detect` is honoured.

The wizard:

1. **Project identity** — asks for project name + one-line description.
2. **Figma MCP verify (hard gate)** — probes both namespaces (`mcp__figma__*` and `mcp__plugin_figma_figma__*`), records the working prefix in `config.figma.mcpToolNamespace`. **If MCP isn't reachable, the wizard aborts and points at `README § Prerequisites § Required — Figma MCP`** — no `config.json` is written. Result: every subsequent `/figma-build` starts with a known-good MCP.
3. **Stack detection** — spawns `project-detector` to identify framework + CSS system + relevant paths. User confirms or overrides.
4. **Design system OR methodology** — design system first; if `none`, then design methodology (atomic / feature-sliced / component-based / flat).
5. **CSS choice** — Tailwind v4/v3 / UnoCSS / vanilla CSS vars / CSS Modules / Sass / vanilla-extract / Panda / styled-components — with examples and a guided migration plan when the detected system differs.
6. **Paths + stories + tests + output-structure** — derived per stack, with confirmation prompts.
7. **Tools** — Claude Code / Cursor / Codex CLI multi-select.
8. **Skills install/strip** — prunes canonical `.figma-pipeline/skills/` to the resolved install set and refreshes per-tool surfaces.
9. **RTK verify (optional)** — `command -v rtk`. If absent, surfaces a one-line pointer to `README § Prerequisites § Optional — RTK` and continues. Never auto-installs.
10. **Graphify detection (optional)** — `command -v graphify`; records status in `config.graphify`. Detect-only (like RTK): never installs the binary, never runs `graphify install`, never builds the graph. If absent, surfaces a one-line pointer to `README § Prerequisites § Optional — Graphify`. Registration (`graphify install --platform <tool>`) and the build (`/graphify .`) are yours to run.
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
