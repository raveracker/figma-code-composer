# Write-access allowlist — protocol

> Read by `.claude/hooks/check-frozen-paths.sh` (PreToolUse) and mirrored by `.cursor/rules/frozen-paths.mdc`. The hook reads `config.writeScope` and blocks any write outside it with `exit 2`.

## Why

The figma-pipeline agents have broad write power (token files, component folders, icons, stories, tests). To stay safe in a target project, **writes are restricted to a configured set of directories** that the wizard derives from your stack choices.

## Default allowlist (before `/init-figma-compose` runs)

Until `.figma-pipeline/config.json` exists, the agent may write only:

- `.figma-pipeline/**`
- `.mcp.json`
- `.codex/**`
- `/tmp/**`

This is enough for `/init-figma-compose` to write the config. Nothing in the target project's source tree is touched.

## Post-`/init-figma-compose` allowlist (derived)

The wizard builds `config.writeScope.allowedDirs` by collecting every path-bearing key:

- `tokens.outputDir`
- `components.atomicLayout.*Dir` (or feature-sliced equivalents, or `flatLayout.componentsDir`)
- `icons.outputDir`
- `stories.outputDir` (when not `co-located`)
- `tests.outputDir` (when not `co-located`)
- `.figma-pipeline/**` always
- `.mcp.json` always
- `.codex/**` always
- `/tmp/**` always

Each entry is converted to a glob with trailing `/**`. The user can hand-edit `config.writeScope.allowedDirs` to add or remove globs after the wizard runs.

## Always-blocked

Regardless of `allowedDirs`, these paths are blocked everywhere:

- `node_modules/**`
- `dist/**`, `build/**`, `.next/**`, `.turbo/**`, `coverage/**`
- `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`
- `.env`, `.env.*` (except `.env.example`)
- `tailwind.config.{js,ts,cjs,mjs}` when `cssSystem.name == "tailwind-v4"` (v4 is CSS-only — config files are illegal)

These live in `config.writeScope.alwaysBlocked`.

## Escape hatch

Set `FP_ALLOW_RESTRICTED_WRITE=1` in the shell that runs Claude Code. The hook short-circuits and allows the write. Use this only for owner-driven config/hook edits.

> **Legacy compatibility:** the previous name `HK_ALLOW_RESTRICTED_WRITE=1` is also accepted by the hook; prefer the `FP_` prefix in new shells.
