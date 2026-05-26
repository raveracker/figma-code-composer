# Cursor skills index

Cursor reads skills from the `.claude/skills/` tree (same physical folder). This index lists the ones most useful for the figma-to-code pipeline; the full set is broader.

## Project-relevant skills

| Skill                       | Use when                                                            | Path                                              |
| --------------------------- | ------------------------------------------------------------------- | ------------------------------------------------- |
| `senior-frontend`           | Writing/reviewing React, Next.js, Vue, Svelte, Solid frontend code | `.claude/skills/senior-frontend/SKILL.md`         |
| `senior-fullstack`          | Scaffolding new projects; stack selection                          | `.claude/skills/senior-fullstack/SKILL.md`        |
| `senior-qa`                 | Generating unit/integration/e2e tests                              | `.claude/skills/senior-qa/SKILL.md`               |
| `senior-security`           | Threat model, vulnerability analysis, secure coding                | `.claude/skills/senior-security/SKILL.md`         |
| `senior-prompt-engineer`    | Refining the wizard/coordinator/builder prompts                    | `.claude/skills/senior-prompt-engineer/SKILL.md`  |
| `tdd-guide`                 | Planning a test matrix before writing tests                        | `.claude/skills/tdd-guide/SKILL.md`               |
| `a11y-audit`                | Auditing built components for WCAG 2.2 AA                          | `.claude/skills/a11y-audit/SKILL.md`              |
| `react-testing-library`     | Writing React tests with RTL idioms                                | `.claude/skills/react-testing-library/SKILL.md`   |
| `vitest`                    | Configuring or writing Vitest tests                                | `.claude/skills/vitest/SKILL.md`                  |
| `playwright-pro`            | Writing E2E tests when `tests.framework == "playwright"`           | `.claude/skills/playwright-pro/SKILL.md`          |
| `storybook`                 | Authoring CSF3 stories                                             | `.claude/skills/storybook/SKILL.md`               |
| `storybook-play-functions`  | Interaction testing inside stories                                 | `.claude/skills/storybook-play-functions/SKILL.md` |
| `storybook-component-documentation` | MDX + autodocs                                             | `.claude/skills/storybook-component-documentation/SKILL.md` |
| `tailwind-4-docs`           | Tailwind v4 questions                                              | `.claude/skills/tailwind-4-docs/SKILL.md`         |
| `building-components`       | Building accessible, composable component APIs                     | `.claude/skills/building-components/SKILL.md`     |
| `ui-design-system`          | Design-system token + component decisions                          | `.claude/skills/ui-design-system/SKILL.md`        |
| `migration-architect`       | Migrating from plain CSS to a framework chosen in `/init` step 4   | `.claude/skills/migration-architect/SKILL.md`     |
| `llm-cost-optimizer`        | When pipeline runs are getting expensive                           | `.claude/skills/llm-cost-optimizer/SKILL.md`      |
| `code-reviewer`             | Reviewing the diff before owner commits                            | `.claude/skills/code-reviewer/SKILL.md`           |
| `pr-review-expert`          | PR review                                                          | `.claude/skills/pr-review-expert/SKILL.md`        |
| `agent-designer`            | Tweaking the pipeline's agent graph                                | `.claude/skills/agent-designer/SKILL.md`          |
| `agent-protocol`            | When defining new inter-agent contracts                            | `.claude/skills/agent-protocol/SKILL.md`          |

## Framework-specific (load per-stack)

- **React**: `react-expert`, `react-best-practices`, `react-performance-optimization`, `react-doctor`, `react-aria`, `next-best-practices`, `vercel-react-best-practices`, `nextjs-react-typescript`
- **Storybook**: `storybook-story-writing`, `storybook-play-functions`, `storybook-component-documentation`
- **Tailwind**: `tailwind-4-docs`

## How to invoke

In Cursor: paste the contents of the skill's `SKILL.md` into the chat as a system-prompt-style block before asking the actual question.

In Claude Code: invoke via `Skill({ skill: "<name>" })` or let the agent auto-trigger via its keywords.

The full catalog lives in `.claude/skills/`. Use `ls .claude/skills/` for the complete list.
