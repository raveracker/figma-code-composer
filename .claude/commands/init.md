---
description: Configure the figma-to-code orchestration scaffold in this project. Runs the 4-step wizard, writes .figma-pipeline/config.json, wires Figma MCP, and emits the derived write allowlist.
argument-hint: "[--re-detect]"
---

# /init — figma-pipeline setup wizard

Spawn the `wizard` agent (model: sonnet). Pass `$ARGUMENTS` verbatim so `--re-detect` is honoured.

The wizard:

1. **Project identity** — asks for project name + one-line description.
2. **Figma MCP connect** — verifies `.mcp.json` has a `figma` entry, opens the auth flow if needed (calls `mcp__figma__authenticate` then `mcp__figma__complete_authentication`).
3. **Stack detection** — spawns `project-detector` to identify framework + CSS system + relevant paths. User confirms or overrides.
4. **Design methodology + CSS choice** — presents the supported methodologies (atomic / feature-sliced / component-based / flat) and CSS systems (Tailwind v4/v3 / UnoCSS / vanilla CSS vars / CSS Modules / Sass / vanilla-extract / panda / styled-components) with one-line examples and trade-offs, and offers a guided migration when the detected system differs from the chosen one.

Final output:

- `.figma-pipeline/config.json` — validated against `.figma-pipeline/config.schema.json`.
- `.mcp.json` — Figma MCP entry confirmed.
- `.codex/config.json` — Codex CLI mirror (only when `tools.codexCli == true`).
- Summary printed to the user listing: project, framework + variant, CSS system, methodology, write allowlist, tools enabled.

The wizard NEVER writes outside the default allowlist (`.figma-pipeline/**`, `.mcp.json`, `.codex/**`, `/tmp/**`). The post-`/init` allowlist takes effect only after the user confirms in step 4.

Do not edit any other file. Do not commit. Do not push.
