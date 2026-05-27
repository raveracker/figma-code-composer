# Using figma-pipeline skills from Codex CLI

Codex does not have a native skill loader. The figma-to-code orchestration pipeline ships a curated skill catalog at:

```
.figma-pipeline/skills/<skill-name>/SKILL.md
```

This file is the Codex-side index. It is wizard-owned: re-written on every `/init-figma-compose` when `tools.codexCli=true`; removed when `tools.codexCli=false`.

## Convention

When a Codex agent prompt (in `.codex/agents/<agent>.md`) tells you to "load skill X" or "invoke skill X":

1. `Read .figma-pipeline/skills/<X>/SKILL.md`.
2. Treat its content as authoritative guidance for the rest of the current run.
3. If the SKILL.md references companion files (e.g. `references/*.md`, `assets/*`), `Read` those too as needed.
4. If the skill directory is missing, record it in your run's `flags[]` and proceed without it — never block.

## Resolution

Which skills apply to the current run is computed by `.figma-pipeline/protocols/skills.md` § _Resolution algorithm_, based on `.figma-pipeline/config.json` (framework, CSS system, design system OR methodology, stories, unit tests, E2E). The wizard's install phase already pruned `.figma-pipeline/skills/` down to the resolved set, so anything still on disk is meant to be loaded — agents do NOT need to re-derive applicability.

For Codex specifically, the agent's first action should typically be:

```
ls .figma-pipeline/skills/
```

to enumerate installed skills, then `Read` each one named in its per-agent additions block (per `protocols/skills.md` § _Per-agent additions_).

## Do NOT

- Do not write into `.figma-pipeline/skills/<name>/` — wizard-owned territory.
- Do not consult `.claude/skills/` from Codex; that surface is Claude-Code-specific.
- Do not invent skill names that don't exist on disk.
