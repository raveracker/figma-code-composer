# figma-code-composer

[![npm](https://img.shields.io/badge/npm-figma--code--composer-cb3837.svg?style=flat-square)](https://www.npmjs.com/package/figma-code-composer) [![license: MIT](https://img.shields.io/badge/license-MIT-3da639.svg?style=flat-square)](./LICENSE) [![Claude Code · Cursor · Codex CLI](https://img.shields.io/badge/works%20with-Claude%20Code%20%C2%B7%20Cursor%20%C2%B7%20Codex%20CLI-6e40c9.svg?style=flat-square)](#quickstart-by-tool)

**A Figma file walks into your AI tool, fully-typed components walk out.** Drop this scaffold into any frontend repo and a multi-agent pipeline turns Figma designs into design tokens, framework-native components, icons, stories, and tests — with a built-in knowledge graph that **reuses components across screens** instead of building duplicates.

Works in **Claude Code**, **Cursor**, and **Codex CLI** — same agents, three entry points, one config.

---

## Install

```bash
# In any frontend project (React / Vue / Angular / Svelte):
npx figma-code-composer
# or, short alias:
npx fcc
```

That copies `.claude/`, `.cursor/`, `.codex/`, `.figma-pipeline/`, `CLAUDE.md`, and `AGENTS.md` into your project. **Nothing is bundled into your application** — your runtime never imports from this package. The CLI runs on demand via `npx`.

> Optional: `npm i -D figma-code-composer` to pin the CLI version. Won't add a runtime dependency.

---

## Quickstart by tool

After `npx figma-code-composer` drops the scaffold, pick your tool. All three use the same `/init` wizard to write `.figma-pipeline/config.json` (the single source of truth), then the same four commands to build from Figma.

### 🟣 Claude Code

```bash
# Inside the project, in your Claude Code session:
/init                                                  # walk the wizard once
/figma-build  https://figma.com/design/<file>?node-id=<id>   # build NEW components
/figma-update https://figma.com/design/<file>?node-id=<id>   # patch EXISTING components
/figma-icons  https://figma.com/design/<file>?node-id=<id>   # icons only
/figma-tokens https://figma.com/design/<file>?node-id=<id>   # design tokens only
```

The wizard uses `AskUserQuestion`; the figma commands spawn `figma-coordinator` which orchestrates `figma-fetcher → token-builder → component-builder + icon-generator → story-author + test-author` in parallel. Per-tier model routing (Haiku / Sonnet / Opus) happens automatically based on the design's complexity score.

### 🟦 Cursor

```
# In Cursor's agent chat, type these as slash commands or natural language:
/init                                          # or: "set up figma-pipeline"
/figma-build  <figma-url>                      # or: "build components from <figma-url>"
/figma-update <figma-url>
/figma-icons  <figma-url>
/figma-tokens <figma-url>
```

Cursor reads the agents from `.cursor/prompts/` and the slash commands from `.cursor/prompts/commands/`. MCP servers are managed via Cursor's settings UI — the wizard will prompt you to enable the Figma MCP server there.

> **Note on model routing.** Cursor uses whatever model you've selected in Settings → Models for the whole session. The coordinator surfaces a recommended size (`sm` / `md` / `lg`) as a chat prefix so you can switch models manually if you want; it does not override your selection.

### 🟢 Codex CLI

```bash
# In a terminal at the project root:
./.codex/wrap.sh init                          # walk the wizard
./.codex/wrap.sh figma-build  <figma-url>      # build NEW
./.codex/wrap.sh figma-update <figma-url>      # patch EXISTING
./.codex/wrap.sh figma-icons  <figma-url>      # icons only
./.codex/wrap.sh figma-tokens <figma-url>      # tokens only

# Optional alias:
alias codex-run='./.codex/wrap.sh'
codex-run figma-build <figma-url>
```

`wrap.sh` simulates Claude Code's lifecycle hooks (`pre-command` → command → `post-command` → `on-exit`) around every `codex run-agent` invocation. Without it, you can still call `codex run <command>` directly, but you lose the manifest/config/token validators. Per-tier model routing passes `--model <openai-id>` via `config.codex.modelMap` (defaults: `gpt-4o-mini` / `gpt-4o` / `o3`).

---

## What you get

| Capability                  | What it does                                                                                          |
| --------------------------- | ----------------------------------------------------------------------------------------------------- |
| **Design tokens**           | Reads Figma variables, emits tokens in your CSS system's native format (CSS-vars, Tailwind theme, Panda config, etc.) |
| **Components**              | Generates framework-native components (TSX / Vue SFC / Angular standalone / Svelte) with cva-style variants and a11y baked in |
| **Icons**                   | SVG → framework-native component with `currentColor` / literal fills + barrel re-exports             |
| **Stories + tests**         | Storybook stories + unit tests (Vitest / Jest / Karma) + optional E2E (Playwright)                   |
| **Knowledge graph**         | Records every built component; reuses across screens instead of duplicating                          |
| **Complexity routing**      | Picks the smallest viable model + skill set per build — saves tokens on easy designs without sacrificing quality on hard ones |
| **Handovers**               | Each run leaves a Markdown summary; `/clear` between runs and re-hydrate from the handover + KG      |
| **Design-system mode**      | Optional: emit AntD / Chakra / Hero UI / Mantine / MUI / Radix / shadcn primitives instead of plain HTML + classes |

All driven by `.figma-pipeline/config.json`, which the `/init` wizard writes from your answers + auto-detection.

---

## How it works

```
        ┌─────────────┐
        │  Figma MCP  │
        └──────┬──────┘
               │
               ▼
        ┌──────────────────┐
        │  figma-fetcher   │   parses, classifies, preserves variable names
        └──────┬───────────┘   detects Figma INSTANCE nodes → enables reuse
               │   manifest.json (single contract, v1.2)
               ▼
        ┌──────────────────────────────────────────────┐
        │           figma-coordinator                  │   queries KG for reuse + complexity-routes
        └─┬──────┬───────┬───────────┬───────────┬─────┘
          │      │       │           │           │
          ▼      ▼       ▼           ▼           ▼
        tokens  icons  components  stories     tests       framework + CSS + DS adapters
          │      │       │           │           │
          └──────┴───────┴───────────┴───────────┘
                         │
                         ▼
                ┌────────────────────┐
                │ fcc kg:merge       │   atomic ledger write
                │ fcc handover       │   .figma-pipeline/kg/handovers/<runId>.md
                └────────────────────┘
```

Every agent reads `.figma-pipeline/config.json` and the active protocols under `.figma-pipeline/protocols/`. Builders never write outside their configured output directories (enforced by `check-frozen-paths.sh` in Claude Code, `.cursor/rules/frozen-paths.mdc` in Cursor, and `wrap.sh` post-command checks in Codex).

---

## The wizard, in one screen

`/init` walks you through:

1. **Project identity** — name + one-line description.
2. **Figma MCP** — enables the official Figma MCP server; handles auth where the tool supports it.
3. **Stack detection** — auto-detects framework + CSS system via `project-detector`; you confirm or override.
4. **Design system OR methodology** — pick one. DS first (Atomic / AntD / Chakra / Hero UI / Mantine / MUI / Radix / shadcn / none); if `none`, then methodology (atomic / feature-sliced / component-based / flat).
5. **CSS choice** — Tailwind v4 / v3 / UnoCSS / vanilla CSS-vars / CSS Modules / Sass / vanilla-extract / Panda / styled-components.
6. **Write paths** — where components, tokens, icons, stories, and tests live (defaults per methodology; override anything).
7. **Stories + Tests** — Storybook (yes/no), unit framework (Vitest / Jest / Karma), E2E toggle (Playwright is automatic).
8. **Output structure** — token file layout (split / combined / framework-native), prefix, naming convention; story/test layout (co-located / parallel tree); icon fill model + barrel.
9. **Tools** — multi-select which AI tools to wire (Claude / Cursor / Codex).
10. **Skill prune** — deletes every skill not relevant to your stack; symlinks the rest into each enabled tool's surface.
11. **RTK detection** — checks for the optional shell-output compressor; offers the install command, never installs.
12. **Report** — prints a summary of every choice + the resolved writes-allowlist.

Output: `.figma-pipeline/config.json` (the contract every agent reads) + `.mcp.json` (Figma MCP wiring).

---

## Knowledge graph + cross-screen reuse

This is the biggest user-visible feature.

**Every component, icon, and design token the pipeline builds is recorded in a local, repo-resident ledger** at `.figma-pipeline/kg/ledger.jsonl`. The next time you build a screen, the coordinator looks up every Figma component instance in that screen against the ledger — and **reuses what's already built** instead of generating duplicates.

### Component reuse in practice

Suppose your Figma file has two screens, both using the same library `Button` component:

```
Screen A (built first)                Screen B (built second)
└─ ProductCard                        └─ CheckoutCard
   ├─ Heading                            ├─ Heading      ← reused (same Figma main component)
   └─ Button  ← built fresh              └─ Button       ← REUSED — coordinator finds it in the ledger
                                                            and emits `import { Button } from '../atoms/Button'`
                                                            instead of creating a duplicate.
```

What makes this work:

- `figma-fetcher` detects `type: "INSTANCE"` nodes in the Figma file and records each one's `mainComponentId` (Figma's stable internal ID).
- `figma-coordinator` queries the KG with that `mainComponentId` + the current framework + CSS system. If all three match an existing ledger entry → silent reuse. If framework/CSS differ → surface a blocking question. If the file's been deleted → flag and rebuild.
- `component-builder` receives a `reusedComposes[]` block in its slice and **emits an import**, never a new file.

The same flow applies to design tokens: token-builder reads the prior `tokenSet` ledger entry, diffs each Figma variable against its `tokenHash`, and emits only the **added + modified** — unchanged tokens skip emission entirely.

### Where it all lives

| File                                            | What                                                                                    |
| ----------------------------------------------- | --------------------------------------------------------------------------------------- |
| `.figma-pipeline/kg/ledger.jsonl`               | Append-only ledger of every built component / icon / token set                          |
| `.figma-pipeline/kg/graph.json`                 | Derived view: composes / uses-token / uses-icon / instance-of edges                     |
| `.figma-pipeline/kg/embeddings.sqlite`          | sqlite-vec table for RAG retrieval (similarity-based hints)                             |
| `.figma-pipeline/kg/handovers/<runId>.md`       | End-of-run summary you can read between sessions                                        |
| `.figma-pipeline/kg/staging/<runId>/`           | In-flight subagent deltas (merged atomically at run end; flock-protected)               |

Disable any time: set `config.knowledgeGraph.enabled = false`. Full protocol: [`.figma-pipeline/protocols/knowledge-graph.md`](.figma-pipeline/protocols/knowledge-graph.md).

### Drift detection

If you move or delete a component file by hand, the next reuse attempt would compose a phantom. `fcc kg:verify` runs before every silent reuse and at the end of every run; failed entries are flagged `orphaned: true` (not deleted). `fcc kg:repair --prune-orphans` lets you clean up. See [`.figma-pipeline/protocols/knowledge-graph.md`](.figma-pipeline/protocols/knowledge-graph.md) § Drift detection & policies for the full edge-case table.

---

## Complexity routing

`figma-fetcher` scores every manifest (0–100) based on node count, variant count, composition depth, unbound values, icon count, and token-reuse ratio. The coordinator resolves a tier and picks the **minimum viable** skill set + model per build:

| Tier      | Skill set per builder                                    | Size  | Model — Claude Code         | Model — Codex CLI         | Cursor (UI-selected)          | 2nd-pass review |
| --------- | -------------------------------------------------------- | ----- | --------------------------- | ------------------------- | ----------------------------- | --------------- |
| trivial   | scope-only                                               | `sm`  | claude-haiku-4-5            | gpt-4o-mini               | (recommendation surfaced)     | no              |
| moderate  | + skip `tdd-guide`; `senior-frontend` only               | `md`  | claude-sonnet-4-6           | gpt-4o                    | (recommendation surfaced)     | no              |
| complex   | full: `senior-frontend` + `tdd-guide` + `senior-qa`      | `lg`  | claude-opus-4-7             | o3                        | (recommendation surfaced)     | no              |
| extreme   | full + `code-reviewer` final pass per component          | `lg`  | claude-opus-4-7             | o3                        | (recommendation surfaced)     | yes             |

Override per tool:
- **Claude Code** — `config.complexity.model.<tier>` (any Claude model ID)
- **Codex CLI** — `config.codex.modelMap.<sm|md|lg>` (any OpenAI model ID your Codex CLI version supports)
- **Cursor** — manual; coordinator surfaces the recommended size as a chat prefix

Full protocol: [`.figma-pipeline/protocols/complexity.md`](.figma-pipeline/protocols/complexity.md).

---

## Handovers

Every successful build writes `.figma-pipeline/kg/handovers/<runId>.md` — what was built, what changed, what's still open, suggested next steps. The coordinator surfaces the handover path at the end of each run:

> Handover written to `.figma-pipeline/kg/handovers/20260527-1407-product-cta.md`. Safe to `/clear`; the next build will rehydrate from this file + the KG.

So you can clear your session between builds without losing context. Next session, the coordinator reads the most recent handover's **Open issues** verbatim and surfaces them before any specialist runs.

Full protocol: [`.figma-pipeline/protocols/handover.md`](.figma-pipeline/protocols/handover.md).

---

## CLI reference (`fcc`)

The `figma-code-composer` binary (alias `fcc`) is the only thing your agents shell out to. It's never bundled into your app.

| Subcommand                                          | Used by                  | Purpose                                                 |
| --------------------------------------------------- | ------------------------ | ------------------------------------------------------- |
| `fcc init [target]`                                 | you                      | Scaffold the pipeline into a project (default)          |
| `fcc doctor`                                        | you                      | Validate config, RTK install, MCP reachability          |
| `fcc complexity <manifest>`                         | figma-coordinator        | Compute complexity score + tier for a manifest          |
| `fcc kg:query --slice <path> --top-k 5`             | figma-coordinator        | RAG retrieval — similarity-based component hints        |
| `fcc kg:query --kind component --figma-node-id <id>`| figma-coordinator        | Instance lookup — exact match for cross-screen reuse    |
| `fcc kg:stage --run-id … --agent … --entry <json>`  | each builder             | Append a ledger delta (parallel-safe; per-agent file)   |
| `fcc kg:merge --run-id …`                           | figma-coordinator        | Atomic merge of staged deltas (flock-protected)         |
| `fcc kg:verify`                                     | figma-coordinator, you   | Check ledger entries still match the filesystem         |
| `fcc kg:repair --prune-orphans`                     | you                      | Remove orphaned entries (after confirm; archived)       |
| `fcc kg:rebuild`                                    | you                      | Rebuild `graph.json` + embeddings from `ledger.jsonl`   |
| `fcc handover --run-id … --manifest <path>`         | figma-coordinator        | Emit handover Markdown for a run                        |

Full spec: [`.figma-pipeline/protocols/cli.md`](.figma-pipeline/protocols/cli.md).

> **Optional: RTK** — [RTK](https://github.com/rtk-ai/rtk) is an external Rust binary that compresses verbose shell-command output (`git status`, `npm test`) 60–90% before it reaches the AI's context. Works across all three tools because it operates at the shell level. The wizard detects it and offers `brew install rtk && rtk init -g` — never installs.

---

## Coverage

- **Frameworks** — React (Next.js, Vite, Remix, Astro, CRA), Vue 3 (Nuxt, Vite, Astro), Angular ≥17 (standalone + signals), Svelte 5 (runes)
- **CSS systems** — Tailwind v4 · Tailwind v3 · UnoCSS · vanilla CSS-vars · CSS Modules · Sass / SCSS · vanilla-extract · Panda CSS · styled-components
- **Design systems** (optional) — Atomic · Ant Design · Chakra UI · Hero UI · Mantine · Material UI · Radix UI · shadcn/ui · *none / custom*
- **Design methodologies** — Atomic Design · Feature-Sliced · Component-Based Architecture · Flat / custom
- **Stories** — Storybook (the only supported framework)
- **Tests** — **unit** (Vitest / Jest / Karma) + **E2E** (Playwright, always — never asked)
- **AI tools** — Claude Code · Cursor · Codex CLI

> **Design System vs Design Methodology are mutually exclusive.** The wizard asks DS first; if `none`, it asks methodology. Picking a DS sets `designMethodology = "custom"` (Atomic is the bridge case — it sets methodology to `atomic` too).

---

## Agents

Eleven agent definitions live identically under `.claude/agents/`, with thin per-tool pointers under `.cursor/prompts/` and `.codex/agents/`:

| Agent                | Owns                                                  |
| -------------------- | ----------------------------------------------------- |
| `wizard`             | `/init` flow; writes `config.json`; prunes skills     |
| `project-detector`   | Reads project tree, returns detection report          |
| `figma-coordinator`  | Orchestrates the build pipeline; never writes source  |
| `figma-fetcher`      | Writes the canonical manifest from Figma MCP          |
| `token-builder`      | Emits tokens in the CSS system's native format        |
| `component-builder`  | Generates framework-native components                 |
| `icon-generator`     | Emits accessible icon components + barrel             |
| `story-author`       | Writes Storybook stories                              |
| `test-author`        | Writes unit + integration + E2E tests                 |
| `tdd-guide`          | Plans the minimum test matrix before tests are written |
| `code-reviewer`      | Reviews recent code for risk / convention-match       |

Per-stack skill resolution (~130 skills total, auto-pruned at `/init`): see [`.figma-pipeline/protocols/skills.md`](.figma-pipeline/protocols/skills.md).

<details>
<summary><strong>Skill baseline + stack-resolved slices (expand)</strong></summary>

### Common baseline (loaded by every agent)

- **Quality + cross-cutting:** `senior-frontend`, `senior-qa`, `senior-security`, `solid`, `responsive-design`, `modern-javascript-patterns`
- **TypeScript:** `typescript`, `typescript-type-system`, `typescript-utility-types`, `typescript-async-patterns`, `zod-schema-validation`
- **Accessibility:** `accessibility-a11y`, `accessibility-compliance`, `a11y-audit`
- **Testing:** `tdd-guide`, `javascript-testing-patterns`, `e2e-testing-patterns`
- **Design system + visual:** `ui-design`, `ui-design-system`, `visual-design-foundations`, `design-system-patterns`
- **Figma (mandatory before any MCP write):** `figma-use`, `figma-create-new-file`, `figma-integration`, `figma-code-connect`, `figma-extract-tokens`, `figma-analyze-frame`, `figma-generate-component`, `figma-generate-design`, `figma-generate-library`, `figma-generate-diagram`, `figma-sync-design-system`, `figma-use-figjam`, `figma-use-slides`
- **CSS baseline:** `css`, `frontend-css-patterns`, `postcss-best-practices`

### Stack-resolved slices

| Axis              | Selector                                | Added skills                                                                                          |
| ----------------- | --------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| Framework         | `react`                                 | `react-best-practices`, `react-component-architecture`, `react-modernization`, `react-state-management`, Zustand/Redux Toolkit families |
| Framework variant | `next` / `astro`                        | `next-best-practices`, `next-cache-components`, `nextjs-server-components`                            |
| Framework variant | `remix`                                 | `remix`                                                                                                |
| Framework         | `vue`                                   | `vue-best-practices`, `vue-typescript`, `vue-composition-api`, `vue-component-patterns`               |
| Framework variant | `nuxt`                                  | `nuxtjs-vue-typescript`                                                                                |
| Framework         | `angular`                               | `angular-developer`, `angular-component`, `angular-signals`, `angular-ssr`, `angular-testing`, …      |
| Framework         | `svelte`                                | `svelte-code-writer`, `svelte-core-bestpractices`                                                     |
| CSS               | `tailwind-v4` / `v3`                    | `tailwindcss`, `tailwindcss-development`, `tailwind-configuration`, `tailwind-components`, …          |
| CSS               | `unocss`                                | `unocss`, `tailwindcss-development`                                                                    |
| CSS               | `css-modules` / `css-vars`              | `css`, `frontend-css-patterns`, `postcss-best-practices`                                              |
| CSS               | `sass`                                  | `sass-best-practices`, `scss-best-practices`, `postcss-best-practices`                                |
| CSS               | `vanilla-extract` / `panda` / `styled-components` | corresponding single-skill bundle                                                            |
| Design system     | `atomic` / `antd` / `chakra` / `heroui` / `mantine` / `mui` / `radix` / `shadcn` | DS-specific families (see `protocols/skills.md`)              |
| Methodology       | `none` AND `atomic` / `feature-sliced` / `component-based` | corresponding methodology-specific bundle                                          |
| Stories           | `stories.enabled = true`                | `storybook-story-writing`, `storybook-component-documentation`, `storybook-args-controls`, …          |
| Unit tests        | `vitest` / `jest`                       | corresponding `vitest-*` or `jest-*` bundle                                                            |
| E2E tests         | `tests.e2e.enabled = true`              | `playwright-pro`, `playwright-fixtures-and-hooks`, `playwright-page-object-model`, …                  |

</details>

---

## Tool support matrix

| Capability                  | Claude Code           | Cursor                             | Codex CLI                          |
| --------------------------- | --------------------- | ---------------------------------- | ---------------------------------- |
| `/init` wizard              | ✅ native             | ✅ inline                          | ✅ via `wrap.sh`                   |
| Multi-agent pipeline        | ✅ native `Agent`     | ✅ inline                          | ✅ `codex run-agent`               |
| MCP integration             | ✅ `.mcp.json`        | ✅ settings UI                     | ✅ `.mcp.json`                     |
| Lifecycle hooks             | ✅ native             | ✅ via `alwaysApply` rules         | ✅ via `wrap.sh`                   |
| Per-call model routing      | ✅ `Agent(model=…)`   | ⚠ user-selected; recommendation shown | ✅ `codex run-agent --model`   |
| KG / handover / complexity  | ✅                    | ✅                                 | ✅                                 |

---

## Configuration

`.figma-pipeline/config.json` is the contract every agent reads. The wizard writes it; you can hand-edit, but rerun `/init --re-detect` after to refresh the writes-allowlist. JSON Schema: [`.figma-pipeline/config.schema.json`](.figma-pipeline/config.schema.json). Reference config: [`.figma-pipeline/config.example.json`](.figma-pipeline/config.example.json).

Key sections:

- `framework`, `language`, `cssSystem`, `designSystem`, `components`, `icons`, `tokens` — stack choices
- `stories`, `tests` — Storybook + unit + E2E
- `complexity` — tier overrides, model overrides, thresholds
- `knowledgeGraph` — enabled, storeDir, embeddings provider, retention, visual regression
- `codex.modelMap` — per-size Codex model IDs (Codex CLI only)
- `rtk` — RTK detection status (read-only)
- `tools` — which AI tools the scaffold is wired for
- `writeScope.allowedDirs` — derived; enforced by `check-frozen-paths.sh`

---

## Repo layout (what landed in your project)

| Path                                                 | Purpose                                                                                |
| ---------------------------------------------------- | -------------------------------------------------------------------------------------- |
| `.figma-pipeline/config.json`                        | Single source of truth — written by `/init`                                            |
| `.figma-pipeline/protocols/`                         | Tool-neutral data contracts (manifest, knowledge-graph, complexity, handover, cli, skills, allowlist, token-strategy, component-layout) |
| `.figma-pipeline/adapters/frameworks/<framework>.md` | Per-framework code-generation templates                                                |
| `.figma-pipeline/adapters/css/<cssSystem>.md`        | Per-CSS-system token + utility recipes                                                 |
| `.figma-pipeline/adapters/design-systems/<name>.md`  | Per-design-system overrides                                                            |
| `.figma-pipeline/skills/`                            | Canonical skill catalog (130 skills, auto-pruned by the wizard)                        |
| `.figma-pipeline/kg/`                                | Knowledge graph data (created on first build)                                          |
| `.claude/agents/` `commands/` `hooks/`               | Claude Code surface                                                                    |
| `.cursor/prompts/` `rules/`                          | Cursor surface (mirrors of agents + hooks)                                             |
| `.codex/agents/` `commands/` `hooks/` `wrap.sh`      | Codex CLI surface with lifecycle simulator                                             |

---

## Credits — bundled skills

The 130 skills shipped under `.figma-pipeline/skills/` are curated from the open-source community. Each retains its original `SKILL.md` (intact, attribution preserved); this scaffold's role is the wizard, agents, hooks, protocols, knowledge graph, and the pipeline that orchestrates them.

If a skill in this catalog is yours and you'd like attribution adjusted (different name, link, removal), please open an issue.

| Source repository | Skills | Sample names |
| ----------------- | -----: | ------------ |
| [thebushidocollective/han](https://github.com/thebushidocollective/han) | 44 | atomic-design-atoms, atomic-design-fundamentals, atomic-design-molecules, … |
| [mindrally/skills](https://github.com/mindrally/skills) | 20 | accessibility-a11y, css, figma-integration, nextjs-react-redux-typescript-cursor-rules, … |
| [wshobson/agents](https://github.com/wshobson/agents) | 10 | accessibility-compliance, design-system-patterns, e2e-testing-patterns, javascript-testing-patterns |
| [analogjs/angular-skills](https://github.com/analogjs/angular-skills) | 10 | angular-component, angular-di, angular-directives, angular-forms, … |
| [alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills) | 7 | a11y-audit, playwright-pro, senior-frontend, senior-qa, … |
| [mui/material-ui](https://github.com/mui/material-ui) | 4 | material-ui-nextjs, material-ui-styling, material-ui-tailwind, material-ui-theming |
| [angular/angular](https://github.com/angular/angular) | 3 | adev-writing-guide, angular-developer, angular-new-app |
| [chakra-ui/chakra-ui](https://github.com/chakra-ui/chakra-ui) | 3 | chakra-ui-builder, chakra-ui-migrate, chakra-ui-refactor |
| [mantinedev/skills](https://github.com/mantinedev/skills) | 3 | mantine-combobox, mantine-custom-components, mantine-form |
| [heroui-inc/heroui](https://github.com/heroui-inc/heroui) | 2 | heroui-migration, heroui-react |
| [vercel-labs/next-skills](https://github.com/vercel-labs/next-skills) | 2 | next-best-practices, next-cache-components |
| [sveltejs/ai-tools](https://github.com/sveltejs/ai-tools) | 2 | svelte-code-writer, svelte-core-bestpractices |
| [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) | 2 | vercel-react-best-practices, vercel-react-view-transitions |
| various single-skill contributors | 21 | see `skills-lock.json` for the full attribution + content hashes                                                       |

Skill provenance (source repo + content hash) is tracked in [`skills-lock.json`](./skills-lock.json) at the repo root.

---

## License

**MIT** — see [LICENSE](./LICENSE) for the full text.

Bundled third-party skills retain their original licenses. Each skill's source repository (linked above) is the authoritative reference; consult the upstream `LICENSE` file before redistributing a specific skill in isolation.

---

## Links

- **Repo**: [github.com/raveracker/figma-code-composer](https://github.com/raveracker/figma-code-composer)
- **npm**: [`figma-code-composer`](https://www.npmjs.com/package/figma-code-composer)
- **Issues**: [github.com/raveracker/figma-code-composer/issues](https://github.com/raveracker/figma-code-composer/issues)
- **Binding rules**: [`CLAUDE.md`](./CLAUDE.md) · [`AGENTS.md`](./AGENTS.md)
- **Protocols** (the source of truth for agent behavior): [`.figma-pipeline/protocols/`](./.figma-pipeline/protocols/)
