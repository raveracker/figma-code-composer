# figma-to-code orchestration

A drop-in, **framework-agnostic** multi-agent pipeline that turns a Figma file into design tokens, components, icons, stories, and tests — wired for **Claude Code**, **Cursor**, and **Codex CLI**.

> See `CLAUDE.md` for the binding rules and `.figma-pipeline/` for the active configuration root.

---

## Install (recommended)

```bash
# In an existing project (any framework):
npx create-figma-pipeline

# Or non-interactive, into a specific target:
npx create-figma-pipeline ./my-app --yes

# Or pick specific tool integrations:
npx create-figma-pipeline --tools claude,cursor --yes
```

The scaffolder drops `.claude/`, `.cursor/`, `.codex/`, `.figma-pipeline/`, `CLAUDE.md`, and `AGENTS.md` into your project. Existing files are not overwritten unless you pass `--force`. Run `npx create-figma-pipeline --help` for the full flag list.

## What you get

| Capability         | What it does                                                                              |
| ------------------ | ----------------------------------------------------------------------------------------- |
| Token generation   | Reads Figma variables, emits tokens in your CSS system's native format                    |
| Component build    | Generates framework-native components (TSX / Vue SFC / Angular standalone / Svelte / …)   |
| Icon pipeline      | SVG → framework-native component with accessibility props + barrel re-exports             |
| Story + test gen   | **Storybook** stories + **unit** tests (Vitest / Jest / Karma) + optional **E2E** (Playwright, always) |
| Design-system mode | Optional: pick Atomic (vanilla Atomic Design) or emit AntD / Chakra / Hero UI / Mantine / MUI / Radix / shadcn primitives instead of plain HTML + classes |
| Skill auto-pruning | Wizard installs only the skills matching your stack choices; everything else is deleted at `/init` for a small consumer bundle |

All driven by a single config (`.figma-pipeline/config.json`) that the `/init` wizard writes for you.

---

## Manual install (without npx)

```bash
# In an existing project (any framework):
git clone <this-repo-url> /tmp/figma-pipeline-scaffold
cp -R /tmp/figma-pipeline-scaffold/{.claude,.cursor,.codex,.figma-pipeline} ./
cp /tmp/figma-pipeline-scaffold/CLAUDE.md ./CLAUDE.md  # or merge if you already have one
```

## Set up

Open the project in your AI tool of choice and run the wizard:

| Tool        | Command                                |
| ----------- | -------------------------------------- |
| Claude Code | `/init`                                |
| Cursor      | Trigger the `figma-pipeline-init` prompt |
| Codex CLI   | `./.codex/wrap.sh init`                |

The wizard walks you through:

1. **Project identity** — name + one-line description
2. **Figma MCP connect** — authorises Figma access (uses the official Figma MCP server)
3. **Stack detection** — auto-detects framework + CSS system; you confirm or override
4. **Design system OR methodology** — pick one. The wizard asks DS first (Atomic / AntD / Chakra / Hero UI / Mantine / MUI / Radix / shadcn / none); if you pick `none`, it then asks for methodology (atomic / feature-sliced / component-based / flat)
5. **CSS choice** — Tailwind v4 / v3 / UnoCSS / vanilla CSS-vars / CSS Modules / Sass / vanilla-extract / Panda / styled-components
6. **Write paths** — where components, tokens, icons, stories, and tests live
7. **Stories + Tests** — Storybook (yes/no); unit-test framework (Vitest / Jest / Karma); E2E (Playwright, automatic when enabled)
8. **Skill prune** — wizard deletes every skill directory not in the resolved set; audit lands in `config.skillsInstall`

Output: `.figma-pipeline/config.json` + a configured `.mcp.json` for Figma.

## Use

```bash
/figma-build  https://figma.com/design/<file>?node-id=<id>   # build NEW
/figma-update https://figma.com/design/<file>?node-id=<id>   # patch EXISTING
/figma-icons  https://figma.com/design/<file>?node-id=<id>   # icons only
/figma-tokens https://figma.com/design/<file>?node-id=<id>   # tokens only
```

Each command spawns the same multi-agent pipeline; the agents read your `config.json` and emit code in your project's idiom.

---

## How it works

```
   ┌─────────────┐
   │  Figma MCP  │
   └──────┬──────┘
          │
          ▼
   ┌──────────────────┐
   │  figma-fetcher   │  parses the file, classifies nodes, preserves variable names
   └──────┬───────────┘
          │  manifest.json (single contract)
          ▼
   ┌──────────────────────────────────────────────┐
   │              figma-coordinator               │  orchestrates, never writes source
   └─┬──────┬───────┬───────────┬───────────┬─────┘
     │      │       │           │           │
     ▼      ▼       ▼           ▼           ▼
   tokens icons components  stories     tests   ← framework + CSS + DS adapters
```

Every agent reads `.figma-pipeline/config.json` and `.figma-pipeline/protocols/figma-manifest.md` before acting.

---

## Agents & their skill classification

Every agent loads a **common baseline** (quality, TypeScript, a11y, testing, Figma, CSS) PLUS an agent-specific extra plus the slices resolved from your `configSnapshot` (framework, CSS system, design-system **or** methodology, stories, unit tests, E2E). Full mapping in [`.figma-pipeline/protocols/skills.md`](.figma-pipeline/protocols/skills.md).

| Agent                | Owns                                                | Agent-specific skills (added on top of the common + stack baseline)                                                                                |
| -------------------- | --------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| `wizard`             | `/init` flow; writes `config.json`; prunes skills    | _orchestration only — no extras_                                                                                                                  |
| `project-detector`   | Reads project tree, returns detection report        | _read-only — no extras_                                                                                                                            |
| `figma-coordinator`  | Routes the build pipeline; never writes source      | _orchestration only — no extras_                                                                                                                  |
| `figma-fetcher`      | Writes the canonical manifest from Figma MCP        | All `figma-*` skills (mandatory `figma-use` + `figma-create-new-file` before any MCP write)                                                        |
| `token-builder`      | Emits tokens in the CSS system's native format      | `design-system-patterns`, `ui-design-system`, `figma-extract-tokens`, `figma-sync-design-system`                                                  |
| `component-builder`  | Generates framework-native components               | `senior-frontend`, `responsive-design`, `accessibility-a11y`, `component-architecture`, `figma-generate-component`                                |
| `icon-generator`     | Emits accessible icon components + barrel           | `accessibility-a11y`, `visual-design-foundations`, `figma-analyze-frame`                                                                          |
| `story-author`       | Writes Storybook stories (+ a11y / visual / interaction tests) | `senior-qa`, `accessibility-a11y`, `e2e-testing-patterns`, full `storybook-*` family when `stories.enabled`                              |
| `test-author`        | Writes unit + integration tests                     | `senior-qa`, `tdd-guide`, `javascript-testing-patterns`, plus the unit-track family (`vitest-*` / `jest-*`) and the Playwright family when E2E on |
| `tdd-guide`          | Plans the minimum test matrix before tests are written | `tdd-guide`, `javascript-testing-patterns`, `senior-qa`                                                                                          |
| `code-reviewer`      | Reviews recent code for risk / convention-match     | `senior-security`, `solid`, per-framework best-practices (`react-best-practices` / `vue-best-practices` / `angular-developer` / `svelte-core-bestpractices`) |

### Common baseline (loaded by every agent)

- **Quality + cross-cutting:** `senior-frontend`, `senior-qa`, `senior-security`, `solid`, `responsive-design`, `modern-javascript-patterns`
- **TypeScript:** `typescript`, `typescript-type-system`, `typescript-utility-types`, `typescript-async-patterns`, `zod-schema-validation`
- **Accessibility:** `accessibility-a11y`, `accessibility-compliance`, `a11y-audit`
- **Testing:** `tdd-guide`, `javascript-testing-patterns`, `e2e-testing-patterns`
- **Design system + visual:** `ui-design`, `ui-design-system`, `visual-design-foundations`, `design-system-patterns`
- **Figma (mandatory before any MCP write):** `figma-use`, `figma-create-new-file`, `figma-integration`, `figma-code-connect`, `figma-extract-tokens`, `figma-analyze-frame`, `figma-generate-component`, `figma-generate-design`, `figma-generate-library`, `figma-generate-diagram`, `figma-sync-design-system`, `figma-use-figjam`, `figma-use-slides`
- **CSS baseline:** `css`, `frontend-css-patterns`, `postcss-best-practices`

### Stack-resolved skill slices (added when the config matches)

| Axis              | Selector                                | Slice                                                                                                |
| ----------------- | --------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Framework         | `framework.name = react`                | `react-best-practices`, `react-component-architecture`, `react-modernization`, `react-state-management`, `vercel-react-best-practices`, `vercel-react-view-transitions`, `solid-react`, `feature-arch`, Zustand/Redux Toolkit families |
| Framework variant | `framework.variant ∈ {next, astro}`     | `next-best-practices`, `next-cache-components`, `nextjs-server-components`, `nextjs-react-redux-typescript-cursor-rules` |
| Framework variant | `framework.variant = remix`             | `remix`                                                                                              |
| Framework         | `framework.name = vue`                  | `vue-best-practices`, `vue-typescript`, `vuejs-typescript-best-practices`, `vue-composition-api`, `vue-component-patterns`, `vue-reactivity-system` |
| Framework variant | `framework.variant = nuxt`              | `nuxtjs-vue-typescript`                                                                              |
| Framework         | `framework.name = angular`              | `angular-developer`, `angular-new-app`, `angular-tooling`, `angular-component`, `angular-routing`, `angular-forms`, `angular-di`, `angular-http`, `angular-signals`, `angular-ssr`, `angular-testing`, `angular-directives` |
| Framework         | `framework.name = svelte`               | `svelte-code-writer`, `svelte-core-bestpractices`                                                    |
| CSS               | `cssSystem.name = tailwind-v4`          | `tailwindcss`, `tailwindcss-development`, `tailwind-configuration`, `tailwind-components`, `tailwind-utility-classes`, `tailwind-responsive-design`, `tailwind-performance`, `tailwind-design-system` |
| CSS               | `cssSystem.name = tailwind-v3`          | Tailwind v4 list minus `tailwind-design-system`                                                      |
| CSS               | `cssSystem.name = unocss`               | `unocss`, `tailwindcss-development`                                                                  |
| CSS               | `cssSystem.name = css-modules`          | `css`, `frontend-css-patterns`, `postcss-best-practices`                                             |
| CSS               | `cssSystem.name = sass`                 | `sass-best-practices`, `scss-best-practices`, `postcss-best-practices`                               |
| CSS               | `cssSystem.name = vanilla-extract`      | `vanilla-extract`                                                                                    |
| CSS               | `cssSystem.name = panda`                | `panda-css`                                                                                          |
| CSS               | `cssSystem.name = styled-components`    | `styled-components-best-practices`                                                                   |
| Design system     | `designSystem.name = atomic`            | `atomic-design-fundamentals`, `atomic-design-quarks/atoms/molecules/organisms/templates/integration`, `design-system-patterns`, `web-component-design` |
| Design system     | `designSystem.name = antd`              | `antd`, `ant-design`                                                                                 |
| Design system     | `designSystem.name = chakra`            | `chakra-ui-builder`, `chakra-ui-refactor`, `chakra-ui-migrate`                                       |
| Design system     | `designSystem.name = heroui`            | `heroui-react`, `heroui-migration`                                                                   |
| Design system     | `designSystem.name = mantine`           | `mantine-custom-components`, `mantine-form`, `mantine-combobox`                                      |
| Design system     | `designSystem.name = mui`               | `material-ui-theming`, `material-ui-styling`, `material-ui-nextjs`, `material-ui-tailwind`           |
| Design system     | `designSystem.name = radix`             | `radix-ui-design-system`                                                                             |
| Design system     | `designSystem.name = shadcn`            | `shadcn`                                                                                             |
| Methodology       | `designSystem.name = none` AND `designMethodology = atomic` | atomic-design family (same as the `atomic` DS slice, minus `web-component-design`)        |
| Methodology       | `designSystem.name = none` AND `designMethodology = feature-sliced` | `feature-sliced-design`                                                            |
| Methodology       | `designSystem.name = none` AND `designMethodology = component-based` | `component-architecture`, `react-component-architecture`, `feature-arch`, `web-component-design` |
| Stories           | `stories.enabled = true`                | `storybook-story-writing`, `storybook-component-documentation`, `storybook-args-controls`, `storybook-configuration`, `storybook-play-functions` |
| Unit tests        | `tests.unit.framework = vitest`         | `vitest-testing-patterns`, `vitest-configuration`, `vitest-performance`                              |
| Unit tests        | `tests.unit.framework = jest`           | `jest-testing-patterns`, `jest-configuration`, `jest-advanced`                                       |
| E2E tests         | `tests.e2e.enabled = true`              | `playwright-pro`, `playwright-cursor-rules`, `playwright-fixtures-and-hooks`, `playwright-page-object-model`, `playwright-test-architecture`, `playwright-bdd-*` |

> **Design system and methodology are mutually exclusive.** Picking a DS automatically sets `designMethodology = "custom"` and skips the methodology skills (`atomic` is the bridge case — selecting it sets methodology to `atomic` too).
>
> **E2E framework is never asked.** When E2E is enabled the wizard sets `tests.e2e.framework = "playwright"` automatically.

---

## Frameworks, CSS systems & design systems supported

**Frameworks:** React (incl. Next.js, Vite, Remix) · Vue 3 (incl. Nuxt) · Angular · Svelte
**CSS systems:** Tailwind v4 · Tailwind v3 · UnoCSS · vanilla CSS-vars · CSS Modules · Sass · vanilla-extract · Panda · styled-components
**Design systems** (optional): **Atomic** (vanilla Atomic Design, no UI lib) · Ant Design · Chakra UI · Hero UI · Mantine · MUI · Radix · shadcn/ui · _none / custom_
**Design methodologies:** Atomic Design · Feature-Sliced · Component-Based Architecture · Flat / custom

When a design system is selected, `component-builder`, `story-author`, `test-author`, `token-builder`, and `icon-generator` all consult `.figma-pipeline/adapters/design-systems/<name>.md` and may modify their framework / CSS-system defaults. The `atomic` choice does NOT override token / CSS / framework adapters — it only enforces atomic-design composition rules.

---

## Tool support

| Capability                  | Claude Code | Cursor | Codex CLI |
| --------------------------- | ----------- | ------ | --------- |
| `/init` wizard              | ✅          | ✅     | ✅        |
| Multi-agent figma pipeline  | ✅          | ✅     | ✅        |
| MCP integration             | ✅          | ✅     | ✅        |
| Lifecycle hooks             | ✅ native   | via `alwaysApply` rules | via `wrap.sh` |

---

## License

TBD.
