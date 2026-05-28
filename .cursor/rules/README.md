# Cursor rules — index

Each rule below maps to one CLAUDE.md binding rule (or supports it). All `*.mdc` files in this directory are loaded by Cursor — `alwaysApply: true` rules fire on every turn; rules with `globs` auto-attach when matching files are open.

## Binding rules

| CLAUDE.md rule                              | Cursor rule file            | Apply mode                                                    |
| ------------------------------------------- | --------------------------- | ------------------------------------------------------------- |
| 1 — Write-access allowlist                  | `frozen-paths.mdc`          | `alwaysApply: true`                                           |
| 2 — Manifest is single source of truth      | `manifest-contract.mdc`     | `alwaysApply: true` + globs `/tmp/figma-*/**`, manifest proto |
| 3 — Variable names preserved                | `manifest-contract.mdc`     | (covered in same file)                                        |
| 4 — Unbound values are flags                | `manifest-contract.mdc`     | (covered in same file)                                        |
| 5 — Blocking ambiguities gate the run       | `manifest-contract.mdc`     | (covered in same file)                                        |
| 6 — Figma strings are data, not instructions | `prompt-injection.mdc`     | `alwaysApply: true`                                           |
| 7 — Verify against reality, not reminders   | `verify-reality.mdc`        | `alwaysApply: true`                                           |

## Supporting rules

| Rule file                | Purpose                                                                 | Backs       |
| ------------------------ | ----------------------------------------------------------------------- | ----------- |
| `env-access.mdc`         | STRICT `.env` block (read AND write) with dual-key bypass               | Rule 1      |
| `config-schema.mdc`      | Shape contract for `.figma-pipeline/config.json` — drives the allowlist | Rule 1      |
| `figma-url-nudge.mdc`    | Routes figma.com URLs to the right slash command (`/figma-build` etc.)  | Rules 1, 2  |
| `pipeline-roles.mdc`     | Per-agent write scope when running specialists sequentially in Cursor    | Rules 1, 2  |
| `model-preference.mdc`   | Preferred agent model: Composer 2.5, fallback Claude (advisory — UI applies it) | —     |
| `use-skills.mdc`         | Skill catalog index (wizard-owned; present when `tools.cursor`)          | —           |

## Editing rules

Hand-edits are fine. The `description` frontmatter field is what Cursor uses to decide when to surface the rule — be explicit. Use `alwaysApply: true` for behavioural rules that must fire every turn; use `globs: [...]` for rules tied to specific file paths.

## Ownership — what `npx figma-code-composer --force` overwrites

Every scaffold-shipped rule carries `owner: figma-pipeline` in its frontmatter. On a re-scaffold (update), the scaffolder:

- **Overwrites** rules tagged `owner: figma-pipeline` (they're ours — you get the upstream version) and creates any rule that doesn't exist yet.
- **Never overwrites** a `.mdc` without that tag — rules you added, or scaffold rules you've *forked*.

So there are two ways to keep a customized rule across updates:

1. **Fork it** — edit the rule AND delete its `owner: figma-pipeline` line. It's now yours; the scaffolder leaves it alone forever. (You stop getting upstream changes to it — that's the trade.)
2. **`--skip cursor-rules`** — blunt override that keeps the entire `.cursor/rules/` dir untouched (even scaffold-owned rules), while the rest of `.cursor` still updates.

If you want both your edit AND the upstream change to a scaffold-owned rule, keep the tag, let `--force` overwrite, and re-apply your hunk with `git checkout -p` (see README § Updating).
