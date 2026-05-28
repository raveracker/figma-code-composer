# .figma-pipeline — runtime configuration root

This directory is the **single source of truth** for the figma-to-code orchestration pipeline. Every agent (Claude Code, Cursor) reads files here before acting.

## Files

| File                              | Purpose                                                                  |
| --------------------------------- | ------------------------------------------------------------------------ |
| `config.json`                     | Live config (created by `/init-figma-compose`; not committed by default — but check git policy in your repo) |
| `config.schema.json`              | JSON Schema for `config.json`                                            |
| `config.example.json`             | Reference config (React + Tailwind v4 + Atomic Design)                   |
| `protocols/figma-manifest.md`     | Data contract between figma-fetcher and downstream agents                |
| `protocols/token-strategy.md`     | How each CSS system maps Figma variables → tokens                        |
| `protocols/component-layout.md`   | Per-framework file conventions + per-methodology layer resolution        |
| `protocols/allowlist.md`          | Write-access policy enforced by hooks                                    |
| `protocols/skills.md`             | Canonical skill mapping — which skills each agent invokes per stack       |
| `adapters/frameworks/<name>.md`   | Per-framework code templates + idiom notes                               |
| `adapters/css/<system>.md`        | Per-CSS-system token + utility recipes                                   |
| `adapters/design-systems/<name>.md` | Per-design-system overrides (Atomic, Chakra, MUI, …) — when `config.designSystem.name != "none"`, this layer modifies framework + CSS adapter output for component shape |

## Editing `config.json`

The `/init-figma-compose` wizard writes this file. You can hand-edit it at any time. Re-run the wizard with `/init-figma-compose --re-detect` to refresh framework + CSS detection without losing path overrides.

## Versioning

`version: "1.0"` is hard-pinned. A schema bump is a breaking change for every agent.
