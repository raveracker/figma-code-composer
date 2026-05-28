# Cursor wizard prompt — `/init-figma-compose` mirror

When the user types `/init-figma-compose` (or asks to "set up figma-pipeline" / "configure the pipeline" / "run the figma wizard"), follow the protocol below — it is the Cursor mirror of `.claude/agents/wizard.md`. (Renamed from `/init` to avoid clashing with built-in `/init` commands.)

Read these first:

- `.figma-pipeline/config.schema.json` — binding contract for the output
- `.figma-pipeline/protocols/figma-manifest.md`
- `.figma-pipeline/protocols/token-strategy.md`
- `.figma-pipeline/protocols/component-layout.md`
- `.figma-pipeline/protocols/allowlist.md`

## Prompt cadence — ONE question at a time

Every prompt is a single chat question. Wait for the user's reply before posing the next one — even when a step lists multiple things to confirm. Each answer can affect what gets asked next (picking the Atomic DS skips the methodology question; high-confidence detector results skip their confirmation entirely). Never batch multiple questions into a single message.

Concretely: where a step describes multiple questions (`Q1` + `Q2` in Project identity, the four detection confirmations in Stack detection, etc.), issue **N separate chat prompts in sequence**. Multi-select (e.g., test tracks, tools) is one question phrased as "pick any of …" and accepts a comma-separated reply.

## Protocol (same as `.claude/agents/wizard.md`)

Steps:

1. **Pre-flight** — handle existing `.figma-pipeline/config.json`: ask overwrite vs incremental vs abort.
2. **Project identity** — ask `name`, wait for reply, then ask `description`. Two separate prompts.
3. **Figma MCP verify (HARD GATE)** — assume the user has already followed `README § Prerequisites § Required — Figma MCP` for Cursor (`/add-plugin figma` OR manual `mcp.json` paste in Settings → Tools & MCP). Run any low-cost MCP read (e.g., metadata) — try `mcp__figma__*` first, fall back to `mcp__plugin_figma_figma__*`. **If MCP is unreachable, abort before writing `config.json` with: "Figma MCP not configured. See README § Prerequisites for Cursor setup, then re-run."** Record `config.figma.mcpToolNamespace` with the working prefix. Per § Step 2 in `.claude/agents/wizard.md`. (Cursor does not expose programmatic auth — the user owns the install + sign-in via Prerequisites.)
4. **Stack detection** — invoke the `project-detector` workflow inline: run the `Glob`/`Read`/`Grep` checks listed in `.claude/agents/project-detector.md` § Detection rules. Then confirm with the user **one prompt at a time** (Q3a framework, Q3b language, Q3c CSS system, Q3d stories framework — skip any whose detected value was `confidence: high`). See `.claude/agents/wizard.md` § Step 3 for the exact sequence.
5. **Design system OR methodology** — ask design system first per `.claude/agents/wizard.md` § Step 3.5. If `none`, then ask design methodology. Picking a DS sets `designMethodology = "custom"` automatically (or `atomic` when DS=atomic).
6. **CSS choice** — present the CSS-system options per `.claude/agents/wizard.md` § Step 4.
7. **Derive paths** — ask the user to confirm or override the path defaults.
8. **Stories + Tests** — Storybook yes/no; unit-test framework (vitest/jest/karma); E2E enabled toggle (Playwright is set automatically — never asked). Per § Step 5.5.
8.5. **Output-structure details** — token file layout (split/combined/framework-native), prefix, naming; story/test layouts; icon fill model + barrel. Skip questions whose values came back high-confidence from the detector. Per § Step 5.6.
9. **Tools** — multi-select; toggle `tools.claudeCode` / `tools.cursor` / `tools.codexCli`.
10. **Compose + validate** — write `.figma-pipeline/config.json`; validate against the schema (use `npx ajv-cli validate` if available; else structural check).
11. **Install / strip skills** — apply the install + per-tool surface pass per `.figma-pipeline/protocols/skills.md` § _Resolution algorithm — Wizard (install phase)_:
    a. Prune canonical `.figma-pipeline/skills/<name>/` to the resolved install set.
    b. If `tools.claudeCode`: ensure `.claude/skills/<name>` symlinks → `../../.figma-pipeline/skills/<name>` for each name in installSet; remove wizard-owned symlinks not in installSet. Else: remove all wizard-owned symlinks under `.claude/skills/`.
    c. If `tools.cursor`: write `.cursor/rules/use-skills.mdc` from the canonical template. Else: delete it.
    d. If `tools.codexCli`: write `.codex/skills.md` from the canonical template. Else: delete it.
    e. Update `config.skillsInstall.installed[]` / `missing[]` / `resolvedAt`.
11.5. **RTK verify** — `command -v rtk` to detect the optional shell-output compressor. Record `config.rtk = { installed, initialized, version, detectedAt }`. If absent, surface a one-line pointer: `"RTK not installed (optional — ~10–15% side-channel token savings). See README § Prerequisites § Optional — RTK."` Never auto-install. Per § Step 7.6.
11.6. **Graphify verify + project-skill registration** — `command -v graphify`. If present, ask the user whether to register `/graphify` project-scoped via `graphify install --project --platform cursor`; record `config.graphify`. If absent, surface a one-line pointer: `"Graphify not installed (optional — codebase knowledge graph). See README § Prerequisites § Optional — Graphify."` Never install the binary yourself. The graph build happens later when the user types `/graphify .` in Cursor's agent chat. Per § Step 7.7.
11.6b. **Codex `./codex-run` shortcut (only when `tools.codexCli==true`)** — write an executable `<projectRoot>/codex-run` (chmod 0755) that does `exec .codex/wrap.sh "$@"`. User invokes `./codex-run figma-build <url>` — no source, no rc edit. Never touch shell rc. Per § Step 7.7b.
11.7. **Patch project `.gitignore`** — idempotently append `.figma-pipeline/config.json`, `.figma-pipeline/scratch/`, `/tmp/figma-*/`, `graphify-out/`, `.mcp.json`. Record `config.gitignorePatch`. Per § Step 7.8.
12. **Report** — print the summary block from `.claude/agents/wizard.md` § Step 8 (includes RTK, Graphify, KG, Complexity, .gitignore lines).

## Write scope

Cursor in agent mode may write only:

- `.figma-pipeline/config.json`
- `.mcp.json` (merge `figma` only)
- `.codex/config.json` (when codexCli is enabled)
- `/tmp/figma-wizard-*` (scratch)
- `.figma-pipeline/skills/<name>/` — **delete only**, at Step 11(a)
- `.claude/skills/<name>` — symlink create/delete, at Step 11(b), only when `tools.claudeCode`
- `.cursor/rules/use-skills.mdc` — write/delete, at Step 11(c)
- `.codex/skills.md` — write/delete, at Step 11(d)
- `<projectRoot>/.gitignore` — append-only, at Step 11.7
- `<projectRoot>/graphify-out/` — written indirectly by the `graphify` binary at Step 11.6

Any other write → stop and tell the user. The Cursor rule `.cursor/rules/frozen-paths.mdc` enforces this in agent mode.

## Differences from Claude Code

- No `AskUserQuestion` tool — present each question as a normal chat prompt, wait for an explicit answer, and confirm before moving on. (Aligns naturally with the "one question at a time" cadence above.)
- No `Agent` tool to spawn `project-detector` as a sub-agent — inline its detection logic.
- MCP auth is user-driven via Cursor settings — guide the user, don't try to call `mcp__figma__authenticate`.

The output (`.figma-pipeline/config.json`) MUST be byte-identical regardless of which tool ran the wizard.
