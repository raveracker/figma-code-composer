# Skills protocol — canonical skill mapping per stack

> Read by every agent (component-builder, story-author, test-author, token-builder, icon-generator, code-reviewer, project-detector, figma-fetcher, figma-coordinator, wizard) before acting. Defines **which skills to install (write to disk) and which to invoke** based on `configSnapshot`.

## Canonical location

All skill content lives under one tool-neutral directory:

```
.figma-pipeline/skills/<skill-name>/SKILL.md
```

This is the **only** place skill files exist. The scaffold ships every supported skill here; at `/init-figma-compose` the wizard prunes the directory down to the resolved install set.

Tools surface skills differently:

| Tool       | How the agent reaches a skill                                                                       |
| ---------- | --------------------------------------------------------------------------------------------------- |
| Claude Code| `.claude/skills/<name>` is a **symlink** the wizard creates at `/init-figma-compose` pointing at canonical. `Skill` tool loads it natively. |
| Cursor     | Cursor has no native skill loader. `.cursor/rules/use-skills.mdc` (wizard-generated) tells Cursor agents to `@`-reference `.figma-pipeline/skills/<name>/SKILL.md` when needed. |
| Codex CLI  | Codex has no native skill loader either. `.codex/skills.md` (wizard-generated) is the index Codex agents `Read` to discover and apply a skill.                       |

The per-tool surfaces (`.claude/skills/`, `.cursor/rules/use-skills.mdc`, `.codex/skills.md`) only exist when the corresponding `tools.*` flag is `true` in `config.json`. If the consumer disables a tool later, the surface is removed on the next `/init-figma-compose`.

## Two distinct phases

1. **Install (wizard, once at `/init-figma-compose`)** — keep skill directories matching the resolved set under `.figma-pipeline/skills/`; delete the rest. Then create per-tool surfaces conditional on `tools.*`. Re-runs cleanly on `/init-figma-compose --re-detect`.
2. **Invoke (agents, per turn)** — each agent invokes the skills assigned to it (see _Per-agent additions_ below). Skills not on disk are recorded in `flags[]` and the agent proceeds — never blocks.

---

## Common skills (always loaded)

Every agent loads these regardless of `configSnapshot`:

### Quality + cross-cutting

| Skill                            | Purpose                                                                  |
| -------------------------------- | ------------------------------------------------------------------------ |
| `senior-frontend`                | Cross-cutting frontend quality bar (React/Next/TS/Tailwind context)      |
| `senior-qa`                      | Test generation + coverage analysis                                      |
| `senior-security`                | Threat modelling, secure-coding review, OWASP                            |
| `solid`                          | SOLID principles + clean code + senior engineering quality                |
| `responsive-design`              | Container queries, fluid type, mobile-first                              |
| `modern-javascript-patterns`     | ES6+ patterns, async / await, modules                                    |

### TypeScript

| Skill                            | Purpose                                                                  |
| -------------------------------- | ------------------------------------------------------------------------ |
| `typescript`                     | TS best practices + type-safety idioms                                   |
| `typescript-type-system`         | strict mode, advanced types, generics, type guards                       |
| `typescript-utility-types`       | mapped types, advanced manipulation                                       |
| `typescript-async-patterns`      | Promises, async/await, async iterators with typing                       |
| `zod-schema-validation`          | Schema validation + inference                                            |

### Accessibility (always)

| Skill                            | Purpose                                                                  |
| -------------------------------- | ------------------------------------------------------------------------ |
| `accessibility-a11y`             | WCAG-grounded a11y patterns                                              |
| `accessibility-compliance`       | WCAG 2.2 compliance + assistive-tech support                             |
| `a11y-audit`                     | Automated a11y scan + violation remediation                              |

### Testing (always)

| Skill                            | Purpose                                                                  |
| -------------------------------- | ------------------------------------------------------------------------ |
| `tdd-guide`                      | Red-green-refactor + test matrix planning                                |
| `javascript-testing-patterns`    | Jest/Vitest + Testing Library idioms                                     |
| `e2e-testing-patterns`           | Playwright + Cypress E2E                                                 |

### Design system + visual

| Skill                            | Purpose                                                                  |
| -------------------------------- | ------------------------------------------------------------------------ |
| `ui-design`                      | UI design best practices                                                 |
| `ui-design-system`               | Design-token generation, component docs, dev handoff                     |
| `visual-design-foundations`      | Typography, color theory, spacing, iconography                           |
| `design-system-patterns`         | DS architecture, theming infra, token strategy                           |

### Figma (always — mandatory for any Figma MCP call)

| Skill                            | Purpose                                                                  |
| -------------------------------- | ------------------------------------------------------------------------ |
| `figma-use`                      | **MANDATORY** prerequisite for any `use_figma` MCP tool call             |
| `figma-create-new-file`          | Prerequisite for `create_new_file` tool calls                            |
| `figma-integration`              | Figma → dev workflow + MCP server patterns                               |
| `figma-code-connect`             | Component → code mapping (`.figma.ts` files)                             |
| `figma-extract-tokens`           | Extract tokens / variables from a Figma file                             |
| `figma-analyze-frame`            | Analyse frame structure + implementation considerations                  |
| `figma-generate-component`       | Generate code from a Figma component / frame                             |
| `figma-generate-design`          | App page → Figma                                                         |
| `figma-generate-library`         | Codebase → Figma DS                                                      |
| `figma-generate-diagram`         | Mermaid → FigJam                                                         |
| `figma-sync-design-system`       | Reconcile Figma ↔ code DS                                                |
| `figma-use-figjam`               | FigJam-context Plugin API                                                |
| `figma-use-slides`               | Slides-context Plugin API                                                |

### CSS (baseline)

| Skill                            | Purpose                                                                  |
| -------------------------------- | ------------------------------------------------------------------------ |
| `css`                            | Modern CSS layout, naming, theming, architecture                         |
| `frontend-css-patterns`          | Framework-agnostic typography / color / motion / spatial patterns        |
| `postcss-best-practices`         | PostCSS configuration + optimisation                                     |

---

## Per-framework skills

Loaded additively when `configSnapshot.framework.name` matches:

### `react`
- `react-best-practices` — TSX quality checklist
- `react-component-architecture` — composition, hooks, functional patterns
- `react-modernization` — class → hooks; concurrent features
- `react-state-management` — Redux Toolkit / Zustand / Jotai / React Query selection
- `vercel-react-best-practices` — Vercel's React perf bar
- `vercel-react-view-transitions` — `<ViewTransition>` API
- `solid-react` — SOLID principles in React 19
- `feature-arch` — feature-based architecture blueprint
- `redux-toolkit` — when `react-state-management` picks Redux
- `zustand-state-management` — when Zustand
- `zustand-store-patterns` — store organisation
- `zustand-middleware` — persist / devtools / immer
- `zustand-typescript` — typed Zustand
- `zustand-advanced-patterns` — transient updates, subscriptions, perf

When `framework.variant ∈ {next, astro}`:
- `next-best-practices` — App Router, RSC, file conventions
- `next-cache-components` — Next 16 PPR / `use cache`
- `nextjs-server-components` — RSC patterns
- `nextjs-react-redux-typescript-cursor-rules` — combined guidance

When `framework.variant == "remix"`:
- `remix` — loaders / actions / nested routes

### `vue`
- `vue-best-practices` — Composition API + `<script setup>` + TS
- `vue-typescript` — Vue + TS + Vite + Pinia
- `vuejs-typescript-best-practices` — performance + Volar + vue-tsc
- `vue-composition-api` — refs, computed, composables
- `vue-component-patterns` — props, emits, slots, provide/inject
- `vue-reactivity-system` — refs, reactive, computed, watchers

When `framework.variant == "nuxt"`:
- `nuxtjs-vue-typescript` — Nuxt + Vue 3 + Composition API

### `angular`
- `angular-developer` — architectural guidance + reactivity
- `angular-new-app` — `ng new` best practices
- `angular-tooling` — CLI usage
- `angular-component` — standalone components + signals
- `angular-routing` — lazy loading, guards, resolvers
- `angular-forms` — Signal Forms (v21+)
- `angular-di` — `inject()`, tokens, provider config
- `angular-http` — `resource()` / `httpResource()` / `HttpClient`
- `angular-signals` — signal / computed / linkedSignal / effect
- `angular-ssr` — `@angular/ssr` + hydration
- `angular-testing` — Vitest / Jasmine + TestBed
- `angular-directives` — attribute + structural + host directives
- `adev-writing-guide` — only when editing `adev/` docs

### `svelte`
- `svelte-code-writer` — Svelte 5 doc lookup + analysis (mandatory for any `.svelte`/`.svelte.ts`)
- `svelte-core-bestpractices` — reactivity, events, styling

---

## Per-CSS-system skills

Loaded additively when `configSnapshot.cssSystem.name` matches:

### `tailwind-v4`
- `tailwindcss` — utility-first idioms
- `tailwindcss-development` — v3/v4 component-class workflows
- `tailwind-configuration` — config / plugins / content paths
- `tailwind-components` — `@apply` + composable patterns
- `tailwind-utility-classes` — class selection
- `tailwind-responsive-design` — breakpoint strategies
- `tailwind-performance` — bundle / purge / scan
- `tailwind-design-system` — design tokens + component libraries

### `tailwind-v3`
- `tailwindcss`, `tailwindcss-development`, `tailwind-configuration`, `tailwind-components`, `tailwind-utility-classes`, `tailwind-responsive-design`, `tailwind-performance`

### `unocss`
- `unocss` — Uno preset / shortcuts / variants
- `tailwindcss-development` (Uno is a Tailwind superset)

### `css-modules`
- `css`, `frontend-css-patterns`, `postcss-best-practices`

### `css-vars` (vanilla)
- `css`, `frontend-css-patterns`

### `sass`
- `sass-best-practices` — indented Sass
- `scss-best-practices` — SCSS variant
- `postcss-best-practices`

### `vanilla-extract`
- `vanilla-extract` — zero-runtime CSS-in-TS

### `panda`
- `panda-css` — `@pandacss` packages, tokens, conditions

### `styled-components`
- `styled-components-best-practices` — CSS-in-JS idioms

---

## Per-design-system skills

Loaded additively when `configSnapshot.designSystem.name` matches:

| `designSystem.name` | Skills                                                                |
| ------------------- | --------------------------------------------------------------------- |
| `none`              | (common only)                                                         |
| `atomic`            | `atomic-design-fundamentals`, `atomic-design-quarks`, `atomic-design-atoms`, `atomic-design-molecules`, `atomic-design-organisms`, `atomic-design-templates`, `atomic-design-integration`, `design-system-patterns`, `web-component-design` |
| `antd`              | `antd`, `ant-design`                                                  |
| `chakra`            | `chakra-ui-builder`, `chakra-ui-refactor`, `chakra-ui-migrate`        |
| `heroui`            | `heroui-react`, `heroui-migration`                                    |
| `mantine`           | `mantine-custom-components`, `mantine-form`, `mantine-combobox`      |
| `mui`               | `material-ui-theming`, `material-ui-styling`, `material-ui-nextjs`, `material-ui-tailwind` |
| `radix`             | `radix-ui-design-system`                                              |
| `shadcn`            | `shadcn`                                                              |

---

## Per-methodology skills

> **Design System and Design Methodology are mutually exclusive.** The wizard asks for `designSystem` first. If the user selects `none`, the wizard then asks for `designMethodology`. If the user selects any DS other than `none`, `designMethodology` is recorded as `custom` (the DS owns layout/composition) — no methodology skills are loaded. The `atomic` DS is the one bridge case: it loads the atomic-design skill family via the DS axis and skips the methodology axis.

Loaded additively when `configSnapshot.designSystem.name == "none"` AND `configSnapshot.designMethodology` matches:

| `designMethodology` | Skills                                                                |
| ------------------- | --------------------------------------------------------------------- |
| `atomic`            | `atomic-design-fundamentals`, `atomic-design-quarks`, `atomic-design-atoms`, `atomic-design-molecules`, `atomic-design-organisms`, `atomic-design-templates`, `atomic-design-integration` |
| `feature-sliced`    | `feature-sliced-design`                                               |
| `component-based`   | `component-architecture`, `react-component-architecture`, `feature-arch`, `web-component-design` |
| `flat`              | (common only)                                                         |
| `custom`            | (common only)                                                         |

---

## Per-stories skills

Loaded additively when `config.stories.enabled == true`. **Storybook is the only supported stories framework** — Histoire and Ladle were removed.

### Stories → `storybook`
- `storybook-story-writing` — story format + variation showcasing
- `storybook-component-documentation` — MDX + autodocs
- `storybook-args-controls` — args / argTypes / controls
- `storybook-configuration` — `.storybook/` config
- `storybook-play-functions` — interaction testing

## Per-tests skills

Tests are split into two independent tracks. The wizard asks the user which they want; each enables its own skill set:

### Unit tests — `config.tests.unit.framework`

- `vitest` → `vitest-testing-patterns`, `vitest-configuration`, `vitest-performance`
- `jest`   → `jest-testing-patterns`, `jest-configuration`, `jest-advanced`
- `karma`  → (Angular-only fallback; no dedicated skill set — common testing skills cover it)

### E2E tests — `config.tests.e2e.framework`

Playwright is the **only** supported E2E framework. The wizard never asks for an E2E framework choice — when E2E is enabled, Playwright is selected automatically.

- `playwright-pro` — production toolkit
- `playwright-cursor-rules` — Cursor + Playwright idioms
- `playwright-fixtures-and-hooks` — reusable fixtures
- `playwright-page-object-model` — POM patterns
- `playwright-test-architecture` — suite structure
- `playwright-bdd-configuration`, `playwright-bdd-gherkin-syntax`, `playwright-bdd-step-definitions` — when BDD is used

---

## Per-agent additions

Some agents load extras beyond the configSnapshot-derived set:

| Agent              | Additional skills                                                  |
| ------------------ | ------------------------------------------------------------------ |
| `figma-fetcher`    | All `figma-*` skills (mandatory `figma-use` + `figma-create-new-file` before any MCP write) |
| `token-builder`    | `design-system-patterns`, `ui-design-system`, `figma-extract-tokens`, `figma-sync-design-system` |
| `component-builder`| `senior-frontend`, `responsive-design`, `accessibility-a11y`, `component-architecture`, `figma-generate-component` |
| `icon-generator`   | `accessibility-a11y`, `visual-design-foundations`, `figma-analyze-frame` |
| `story-author`     | `senior-qa`, `accessibility-a11y`, `e2e-testing-patterns`, all `storybook-*` skills when `stories.enabled` |
| `test-author`      | `senior-qa`, `tdd-guide`, `javascript-testing-patterns`, plus unit-track skills (`vitest-*` / `jest-*`) and the Playwright family when `tests.e2e.enabled` |
| `code-reviewer`    | `senior-security`, `solid`, per-framework best-practices skill (`react-best-practices` / `vue-best-practices` / `angular-developer` / `svelte-core-bestpractices`) |
| `project-detector` | (read-only — no extra skills) |
| `wizard`           | (orchestration only — no extra skills) |
| `figma-coordinator`| (orchestration only — no extra skills; specialists load their own) |

---

## Resolution algorithm

Pseudocode shared by the wizard (install/strip phase) and every agent (per-turn invoke phase):

```
def resolve_skills(configSnapshot, agent_name=None):
    skills = set(COMMON_ALWAYS)
    skills |= FRAMEWORK_SKILLS[configSnapshot.framework.name]
    if configSnapshot.framework.variant in {"next", "astro", "remix", "nuxt"}:
        skills |= VARIANT_SKILLS[configSnapshot.framework.variant]
    skills |= CSS_SKILLS[configSnapshot.cssSystem.name]

    # Design System OR Methodology — never both.
    if configSnapshot.designSystem.name != "none":
        skills |= DESIGN_SYSTEM_SKILLS[configSnapshot.designSystem.name]
    else:
        skills |= METHODOLOGY_SKILLS[configSnapshot.designMethodology]

    if configSnapshot.stories and configSnapshot.stories.enabled:
        skills |= STORYBOOK_SKILLS

    if configSnapshot.tests:
        if configSnapshot.tests.unit and configSnapshot.tests.unit.enabled:
            skills |= UNIT_TESTS_SKILLS[configSnapshot.tests.unit.framework]
        if configSnapshot.tests.e2e and configSnapshot.tests.e2e.enabled:
            skills |= PLAYWRIGHT_SKILLS

    if agent_name:
        skills |= AGENT_EXTRAS[agent_name]
    return sorted(skills)
```

### Wizard (install phase)

At `/init-figma-compose` (and on every `--re-detect`):

1. Compute `installSet = resolve_skills(configSnapshot)` (no `agent_name` — superset of every agent's load).
2. Union every per-agent extra into `installSet` so each downstream agent's mandatory skills are on disk.
3. **Prune canonical** — via the vetted `fcc skills:prune --keep "<comma-joined installSet>" --json`, never a hand-authored `rm -rf` over a shell-expanded list. The command deletes only dirs under `.figma-pipeline/skills/` not in the keep-set (each target basename-scoped to that dir), returns `removed[]`/`missing[]`/counts, and syncs `skills-lock.json`. **Safety invariant (enforced, non-bypassable):** the prune deletes nothing and exits non-zero when the keep-set is empty **or** when it is disjoint from the on-disk set (which would delete the whole catalog — the historical failure mode). Record returned `missing[]` in `config.skillsInstall.missing[]`.
4. **Tool-conditional surfaces** — re-apply each per-tool exposure based on `config.tools.*`:
   - `tools.claudeCode == true`:
     - Ensure `.claude/skills/` exists. For every `name` in installSet, ensure `.claude/skills/<name>` is a symlink → `../../.figma-pipeline/skills/<name>`. Remove any `.claude/skills/<name>` that is no longer in installSet OR that is not a symlink the wizard created (leave consumer-owned content untouched if its target is not `../../.figma-pipeline/skills/...`).
     - `tools.claudeCode == false` → `rm -rf .claude/skills/` (only removes wizard-managed symlinks; any non-symlink children are preserved by checking each entry first).
   - `tools.cursor == true`: write `.cursor/rules/use-skills.mdc` (overwrite always — wizard-owned). `tools.cursor == false` → delete the file if present.
   - `tools.codexCli == true`: write `.codex/skills.md` (overwrite always — wizard-owned). `tools.codexCli == false` → delete the file if present.
5. Write `config.skillsInstall.installed[] = sorted(installSet ∩ on-disk-under-canonical)` and `config.skillsInstall.resolvedAt = <ISO-8601>` for auditability.

### Agent (invoke phase)

For each resolved skill, the agent invokes it via the `Skill` tool **once** at the start of its run. Skills that are not on disk are recorded in `flags[]` and the agent proceeds — never blocks.

---

## Out-of-band

`skills-lock.json` at the repo root tracks the provenance (source repo + hash) of each installed skill. The figma-pipeline does NOT depend on that lockfile shape — agents reference skills by name only and tolerate missing ones — but it SHOULD stay in sync with `.figma-pipeline/skills/` so a consumer running `npm audit`-style integrity checks gets clean output.

After any change to the installed set (the wizard's `/init-figma-compose` prune, a `--re-detect` re-pass, or a manual install/uninstall), regenerate the lock so its keys match `ls .figma-pipeline/skills/`. A quick filter:

```js
// node — prune lock to on-disk only
const fs=require('fs');
const lock=JSON.parse(fs.readFileSync('skills-lock.json','utf8'));
const onDisk=new Set(fs.readdirSync('.figma-pipeline/skills'));
lock.skills=Object.fromEntries(Object.entries(lock.skills).filter(([k])=>onDisk.has(k)));
fs.writeFileSync('skills-lock.json', JSON.stringify(lock,null,2)+'\n');
```
