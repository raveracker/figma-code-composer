# figma-code-composer

<p align="center">
<img src="./assets/hero.png" alt="figma-code-composer" width="500"/>
</p>

<p align="center">
  <a href="https://www.npmjs.com/package/figma-code-composer"><img src="https://img.shields.io/badge/npm-figma--code--composer-cb3837.svg?style=flat-square" alt="npm"/></a>
  <a href="https://www.npmjs.com/package/figma-code-composer"><img src="https://img.shields.io/npm/v/figma-code-composer.svg?style=flat-square&label=version&color=blue" alt="version"/></a>
  <a href="./LICENSE"><img src="https://img.shields.io/badge/license-MIT-3da639.svg?style=flat-square" alt="license: MIT"/></a>
  <a href="#quickstart"><img src="https://img.shields.io/badge/works%20with-Claude%20Code%20%C2%B7%20Cursor%20%C2%B7%20Codex%20CLI-6e40c9.svg?style=flat-square" alt="Claude Code · Cursor · Codex CLI"/></a>
  <a href=".figma-pipeline/skills/"><img src="https://img.shields.io/badge/bundled%20skills-137-orange.svg?style=flat-square" alt="137 bundled skills"/></a>
</p>


**A Figma file walks into your AI tool, fully-typed components walk out.** Drop this scaffold into any frontend repo and a multi-agent pipeline turns Figma designs into design tokens, framework-native components, icons, stories, and tests — with a built-in knowledge graph that **reuses components across screens** instead of building duplicates.

Works in **Claude Code**, **Cursor**, and **Codex CLI** — same agents, three entry points, one config.

---

## Install

```bash
# In any frontend project (React / Vue / Angular / Svelte):
npx figma-code-composer        # or the short alias: npx fcc
```

That copies `.claude/`, `.cursor/`, `.codex/`, `.figma-pipeline/`, `CLAUDE.md`, and `AGENTS.md` into your project. **Nothing is bundled into your application** — your runtime never imports from this package. The CLI runs on demand via `npx`. Optionally pin with `npm i -D figma-code-composer`.

---

## Prerequisites

Before running `/init-figma-compose` you need to have **Figma MCP connected** in your AI tool of choice. **Graphify** and **RTK** are optional but recommended — they're both external user-level tools the pipeline benefits from.

### Required — Figma MCP

Connects your AI tool to your Figma files. The wizard's Step 2 hard-gates on this: without a reachable Figma MCP, `config.json` is never written. Pick the tool you use:

#### Claude Code

**Option A — Plugin install (recommended):**

```bash
claude plugin install figma@claude-plugins-official
```

**Option B — Manual MCP add:**

```bash
claude mcp add --transport http figma https://mcp.figma.com/mcp
```

**Managing MCP servers:**

```bash
claude mcp list                  # list configured servers
claude mcp get figma             # details for the figma server
claude mcp remove figma          # remove it
```

#### Cursor

**Option A — Plugin install (recommended):**

In Cursor's agent chat, type:

```
/add-plugin figma
```

**Option B — Manual MCP add:**

1. Open Cursor → Settings → Cursor Settings
2. Click **Tools & MCP**
3. Under **MCP Tools**, click **+** to add a custom MCP server
4. Paste this into the `mcp.json` and save:

```json
{
  "mcpServers": {
    "Figma": {
      "url": "https://mcp.figma.com/mcp"
    }
  }
}
```

#### Codex CLI

```bash
codex                            # open Codex
/plugins                         # then run
```

Search for **Figma** in the plugin list and press Enter to install.

### Optional — Graphify (`/graphify` codebase knowledge graph)

[Graphify](https://github.com/safishamsi/graphify) turns the project tree into a queryable knowledge graph at `graphify-out/`. Once installed, type `/graphify .` (Codex: `$graphify .`) in your assistant and you get three files:

- `graph.html` — open in any browser, click nodes, filter, search
- `GRAPH_REPORT.md` — key concepts, surprising connections, suggested questions
- `graph.json` — full graph, queryable any time without re-reading your files

**Why use it.** `component-builder`'s `priorReuseHints[]` and `code-reviewer`'s cross-file impact analysis both prefer `graphify-out/graph.json` when present, so the agents stop grepping raw files for context. Cuts repeated `Read`/`Grep` tool calls on multi-component builds and gives the assistant a holistic view of the codebase that survives `/clear`.

**Install (PyPI package is `graphifyy` — double-y; CLI command is `graphify`):**

```bash
# Pick one:
uv tool install graphifyy        # recommended (puts on PATH automatically)
pipx install graphifyy
pip install graphifyy
```

**Register for your AI tool** (the wizard's Step 7.7 will run `--project` for you when graphify is on PATH; or run manually):

```bash
graphify install --platform claude       # Claude Code (global skill)
graphify install --platform cursor       # Cursor
graphify install --platform codex        # Codex CLI (uses $graphify)
# or:
graphify install --project --platform <claude|cursor|codex>   # project-scoped instead of global
```

**Build the graph** (you do this inside your assistant chat, not the wizard):

```
/graphify .
```

Skip it if you don't want the codebase indexed — the pipeline runs identically with or without.

### Optional — RTK (shell-output compression)

[RTK](https://github.com/rtk-ai/rtk) is a Rust binary that sits between your shell and your AI tool, filtering and compressing verbose command output (`git status`, `npm test`, `cargo test`, `ls`, …) **60-90% before the model reads it.**

**Why use it.** Realistic savings on a typical pipeline run: ~10-15% of side-channel tokens (Bash tool calls only — does NOT compress Figma MCP payloads, generated code, or built-in `Read`/`Grep`/`Glob`). For multi-build sessions on large repos the savings compound. Free if you already use Homebrew.

**Install (pick one):**

```bash
brew install rtk
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
cargo install --git https://github.com/rtk-ai/rtk
```

**Init for your AI tool** (do this once per tool you use — RTK is user-level, modifies your global tool config):

```bash
rtk init -g                      # Claude Code (default)
rtk init --agent cursor          # Cursor
rtk init -g --codex              # Codex CLI
```

Restart your AI tool after init, then test: `git status` (auto-rewritten to `rtk git status`). Re-running `/init-figma-compose` or `fcc doctor` picks up the new state in `config.rtk`.

**Why the wizard doesn't auto-install RTK or Graphify** — both modify user-level state (`~/.claude/settings.json`, shell rc files). A per-project init shouldn't reconfigure your whole workstation, so the wizard detects and offers — you own the install command.

---

## Quickstart

All three tools share the same commands. Run them inside the project after `npx figma-code-composer`:

| Tool          | Run wizard                                         | Run a build                          |
| ------------- | -------------------------------------------------- | ------------------------------------ |
| Claude Code   | `/init-figma-compose`                              | `/figma-build <url>`                 |
| Cursor        | `/init-figma-compose` (or "set up figma-pipeline") | `/figma-build <url>`                 |
| Codex CLI     | `./.codex/wrap.sh init-figma-compose` (or `./codex-run init-figma-compose`) | `./codex-run figma-build <url>` |

Available commands (all tools): `figma-build`, `figma-update`, `figma-icons`, `figma-tokens`.

**Per-tool specifics:**

- **Claude Code** uses `AskUserQuestion` for the wizard and the `Agent` tool for dispatch. Per-tier model routing (Haiku / Sonnet / Opus) is automatic via `Agent(model=…)`.
- **Cursor** reads agents from `.cursor/prompts/` and runs MCP through Cursor's Settings → MCP UI. The wizard **hard-gates** on this: it verifies Figma MCP with a low-cost read before writing `config.json`. Model routing is user-selected; the coordinator surfaces a recommended size (`sm`/`md`/`lg`) as a chat prefix.
- **Codex CLI** wraps every command through `.codex/wrap.sh`, which simulates Claude Code's lifecycle hooks (`pre-command` → cmd → `post-command` → `on-exit`). When the wizard sees `tools.codexCli = true`, it writes `./codex-run` (chmod 0755) at the project root — `./codex-run <cmd>` works from the project root with no source step, no shell-rc edit, no direnv. Per-tier routing passes `--model <openai-id>` via `config.codex.modelMap`.

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

All driven by `.figma-pipeline/config.json`, written by `/init-figma-compose`.

---

## How it works

```
        ┌─────────────┐
        │  Figma MCP  │
        └──────┬──────┘
               ▼
        ┌──────────────────┐
        │  figma-fetcher   │   parses, classifies, preserves variable names
        └──────┬───────────┘   detects INSTANCE nodes → enables reuse
               │   manifest.json (single contract, v1.2)
               ▼
        ┌──────────────────────────────────────────────┐
        │           figma-coordinator                  │   queries KG for reuse + complexity-routes
        └─┬──────┬───────┬───────────┬───────────┬─────┘
          ▼      ▼       ▼           ▼           ▼
        tokens  icons  components  stories     tests      ← per-framework + CSS + DS adapters
          └──────┴───────┴───────────┴───────────┘
                         ▼
                ┌────────────────────┐
                │ fcc kg:merge       │   atomic ledger write
                │ fcc handover       │   .figma-pipeline/kg/handovers/<runId>.md
                └────────────────────┘
```

Every agent reads `config.json` + the active protocols under `.figma-pipeline/protocols/`. Builders never write outside their configured output directories (enforced by `check-frozen-paths.sh` in Claude Code, `.cursor/rules/frozen-paths.mdc` in Cursor, `wrap.sh` post-command checks in Codex).

---

## The wizard, in one screen

`/init-figma-compose` (renamed from `/init` to avoid shadowing the built-in) walks through 15 steps. Full protocol: [`.claude/agents/wizard.md`](./.claude/agents/wizard.md). Summary:

| Step | What it does | Notes |
|---:|---|---|
| 1  | Project identity | Name + one-line description. |
| 2  | **Figma MCP — HARD GATE** | Verifies `.mcp.json`, drives auth, proves reachability with one cheap read. **No `config.json` until MCP is live.** Failure → exit 3. |
| 3  | Stack detection | `project-detector` reads the repo and surfaces framework + CSS + paths; you confirm or override. |
| 4  | DS **OR** methodology | Design system first (Atomic / AntD / Chakra / HeroUI / Mantine / MUI / Radix / shadcn / none). If `none` → methodology (atomic / feature-sliced / component-based / flat). |
| 5  | CSS choice | Tailwind v4 / v3 / UnoCSS / CSS-vars / CSS Modules / Sass / vanilla-extract / Panda / styled-components. |
| 6  | Write paths | Components / tokens / icons / stories / tests — defaults per methodology, override anything. |
| 7  | Stories + tests | Storybook (yes/no), unit framework (Vitest / Jest / Karma), E2E toggle (Playwright is automatic, never asked). |
| 8  | Output structure | Token layout (split / combined / framework-native), prefix, naming; story/test layout; icon fill model + barrel. |
| 9  | Tools | Multi-select: Claude Code / Cursor / Codex CLI. |
| 10 | Skill prune | Deletes irrelevant skills; symlinks the rest into each enabled tool's surface. |
| 11 | RTK detection | Detects optional shell-output compressor. Prints per-tool init commands matched to your `config.tools.*`. **Never auto-installs** ([why](#optional-rtk--graphify-user-level-tools)). |
| 12 | Graphify registration | Detects the external `graphify` CLI. If present, runs `graphify install --project --platform <tool>`. **Does not build the graph** — that's `/graphify .` in your assistant. |
| 13 | `./codex-run` shortcut | When `tools.codexCli=true`, writes an executable wrapper at the project root. Zero extra intervention beyond `./codex-run <cmd>`. |
| 14 | `.gitignore` patch | Idempotent append: `.figma-pipeline/config.json`, `.figma-pipeline/scratch/`, `/tmp/figma-*/`, `graphify-out/`, `.mcp.json`. |
| 15 | Report | Summary + write-allowlist + reminder: *"Build the graph anytime by typing /graphify . in your assistant."* |

Outputs:
- `.figma-pipeline/config.json` — the contract every agent reads (validated)
- `.mcp.json` — Figma MCP wiring, proven reachable at wizard time (`config.figma.mcpVerifiedAt`)
- `<projectRoot>/.gitignore` — patched (one append-only marker block)
- `<projectRoot>/codex-run` — wrapper executable, only when Codex CLI is enabled
- `.claude/skills/graphify/SKILL.md` (and Cursor / Codex equivalents) — written by `graphify install --project` when graphify is on PATH

---

## Knowledge graph + cross-screen reuse

The biggest user-visible feature. Every component, icon, and token the pipeline builds is recorded in `.figma-pipeline/kg/ledger.jsonl`. On the next build the coordinator looks up every Figma instance against the ledger and **emits an `import` instead of generating a duplicate**.

```
Screen A (built first)            Screen B (built second)
└─ ProductCard                    └─ CheckoutCard
   ├─ Heading                        ├─ Heading      ← reused (same Figma main component)
   └─ Button  ← built fresh          └─ Button       ← REUSED: coordinator finds it in the ledger
                                                       and emits `import { Button } from '../atoms/Button'`
```

What enables it:

- `figma-fetcher` records each `INSTANCE` node's `mainComponentId` (Figma's stable internal ID).
- `figma-coordinator` queries the KG with `{ mainComponentId, framework, cssSystem }`. All three match → silent reuse. Framework/CSS mismatch → blocking question. File missing on disk → flag + rebuild.
- `component-builder` receives a `reusedComposes[]` slice block and emits an import, never a new file.

The same flow applies to design tokens: token-builder diffs each Figma variable against its `tokenHash` and emits only added / modified.

| File                                            | What                                                                      |
| ----------------------------------------------- | ------------------------------------------------------------------------- |
| `.figma-pipeline/kg/ledger.jsonl`               | Append-only ledger of every built component / icon / token set            |
| `.figma-pipeline/kg/graph.json`                 | Derived view: composes / uses-token / uses-icon / instance-of edges       |
| `.figma-pipeline/kg/embeddings.sqlite`          | sqlite-vec table for RAG similarity hints                                 |
| `.figma-pipeline/kg/handovers/<runId>.md`       | End-of-run summary; rehydrate context after `/clear`                       |
| `.figma-pipeline/kg/staging/<runId>/`           | In-flight subagent deltas (flock-protected, merged atomically at run end) |

Drift handling: `fcc kg:verify` runs before every silent reuse and at end-of-run. Failed entries are flagged `orphaned: true` (not deleted). Clean with `fcc kg:repair --prune-orphans`. Disable any time: `config.knowledgeGraph.enabled = false`. Full protocol: [`protocols/knowledge-graph.md`](.figma-pipeline/protocols/knowledge-graph.md).

---

## Complexity routing

`figma-fetcher` scores every manifest 0–100 (node count, variants, depth, unbound values, icon count, token-reuse). The coordinator resolves a tier and picks the **minimum viable** skill set + model:

| Tier      | Skills per builder                                  | Size | Claude Code        | Codex CLI       | Cursor                  | 2nd-pass |
| --------- | --------------------------------------------------- | ---- | ------------------ | --------------- | ----------------------- | -------- |
| trivial   | scope-only                                          | `sm` | claude-haiku-4-5   | gpt-4o-mini     | recommendation surfaced | no       |
| moderate  | + skip `tdd-guide`; `senior-frontend` only          | `md` | claude-sonnet-4-6  | gpt-4o          | recommendation surfaced | no       |
| complex   | full: `senior-frontend` + `tdd-guide` + `senior-qa` | `lg` | claude-opus-4-7    | o3              | recommendation surfaced | no       |
| extreme   | full + `code-reviewer` final pass per component     | `lg` | claude-opus-4-7    | o3              | recommendation surfaced | yes      |

Override per tool: `config.complexity.model.<tier>` (Claude), `config.codex.modelMap.<sm|md|lg>` (Codex), manual in Cursor. Full protocol: [`protocols/complexity.md`](.figma-pipeline/protocols/complexity.md).

---

## Handovers

Every successful build writes `.figma-pipeline/kg/handovers/<runId>.md` — what was built, what changed, what's still open, suggested next steps. Surfaced at run end:

> Handover written to `.figma-pipeline/kg/handovers/20260527-1407-product-cta.md`. Safe to `/clear`; the next build will rehydrate from this file + the KG.

Next session, the coordinator reads the most recent handover's **Open issues** verbatim before any specialist runs. Full protocol: [`protocols/handover.md`](.figma-pipeline/protocols/handover.md).

---

## CLI reference (`fcc`)

The only thing your agents shell out to. Never bundled into your app.

| Subcommand                                          | Used by                  | Purpose                                                 |
| --------------------------------------------------- | ------------------------ | ------------------------------------------------------- |
| `fcc init [target]`                                 | you                      | Scaffold the pipeline into a project                    |
| `fcc doctor`                                        | you                      | Validate config, RTK install, MCP reachability          |
| `fcc complexity <manifest>`                         | figma-coordinator        | Compute complexity score + tier                         |
| `fcc kg:query --slice <path> --top-k 5`             | figma-coordinator        | RAG retrieval — similarity-based component hints        |
| `fcc kg:query --kind component --figma-node-id <id>`| figma-coordinator        | Instance lookup for cross-screen reuse                  |
| `fcc kg:stage --run-id … --agent … --entry <json>`  | each builder             | Append a ledger delta (parallel-safe, per-agent file)   |
| `fcc kg:merge --run-id …`                           | figma-coordinator        | Atomic merge of staged deltas (flock-protected)         |
| `fcc kg:verify`                                     | figma-coordinator + you  | Check ledger entries still match the filesystem         |
| `fcc kg:repair --prune-orphans`                     | you                      | Remove orphaned entries (after confirm; archived)       |
| `fcc kg:rebuild`                                    | you                      | Rebuild `graph.json` + embeddings from `ledger.jsonl`   |
| `fcc handover --run-id … --manifest <path>`         | figma-coordinator        | Emit handover Markdown                                  |

Full spec: [`protocols/cli.md`](.figma-pipeline/protocols/cli.md).

---

## Optional tools deep-dive

Install instructions for **Figma MCP**, **Graphify**, and **RTK** are in [Prerequisites](#prerequisites). This section covers runtime behavior + scope.

**RTK** — once installed and `rtk init`-ed for your AI tool, it transparently rewrites Bash commands (`git status` → `rtk git status`, `npm test` → `rtk npm test`, etc.) to compress output 60-90% before the model reads it. **Runtime scope:** Bash tool calls only — does NOT touch Figma MCP payloads, generated code, the Anthropic/OpenAI API itself, or Claude Code's built-in `Read`/`Grep`/`Glob` (those bypass the Bash hook). Use `rtk read`/`rtk grep` explicitly if you want compression there. Savings: ~10-15% of side-channel tokens on a typical pipeline run.

**Graphify** — once installed and registered, **you** trigger the graph build by typing `/graphify .` (Codex: `$graphify .`) inside your AI assistant. The wizard never builds the graph itself — that step needs to run inside the assistant where graphify's prompt + Mermaid rendering live. `graphify-out/` is gitignored by the wizard's Step 14 regardless of whether graphify is installed. Skip it if you don't want the codebase indexed; the pipeline runs identically without.

**Why the wizard doesn't auto-install either** — both modify user-level state (`~/.claude/settings.json`, shell rc files). A per-project init shouldn't reconfigure your whole workstation — you own the install command. The wizard's Steps 7.6 (RTK) and 7.7 (Graphify) detect, offer per-tool init commands matched to `config.tools.*`, and record status in `config.rtk` / `config.graphify` — never run `brew install` or `uv tool install` themselves.

---

## Coverage

- **Frameworks** — React (Next.js · Vite · Remix · Astro · CRA) · Vue 3 (Nuxt · Vite · Astro) · Angular ≥17 (standalone + signals) · Svelte 5 (runes)
- **CSS systems** — Tailwind v4 · Tailwind v3 · UnoCSS · vanilla CSS-vars · CSS Modules · Sass / SCSS · vanilla-extract · Panda CSS · styled-components
- **Design systems** — Atomic · Ant Design · Chakra UI · Hero UI · Mantine · Material UI · Radix UI · shadcn/ui · *none / custom*
- **Methodologies** — Atomic Design · Feature-Sliced · Component-Based Architecture · Flat / custom
- **Stories** — Storybook (only supported framework) · **Tests** — Vitest / Jest / Karma + Playwright (E2E always)
- **AI tools** — Claude Code · Cursor · Codex CLI

> Design System and Methodology are **mutually exclusive**. Wizard asks DS first; if `none`, asks methodology. Picking a DS sets `designMethodology = "custom"` (Atomic is the bridge — sets methodology to `atomic`).

---

## Agents

Eleven agent definitions under `.claude/agents/`, with per-tool pointers under `.cursor/prompts/` and `.codex/agents/`.

| Agent                | Owns                                                  |
| -------------------- | ----------------------------------------------------- |
| `wizard`             | `/init-figma-compose` flow; writes `config.json`; prunes skills |
| `project-detector`   | Reads project tree, returns detection report          |
| `figma-coordinator`  | Orchestrates the pipeline; never writes source        |
| `figma-fetcher`      | Writes the canonical manifest from Figma MCP          |
| `token-builder`      | Emits tokens in the CSS system's native format        |
| `component-builder`  | Generates framework-native components                 |
| `icon-generator`     | Emits accessible icon components + barrel             |
| `story-author`       | Writes Storybook stories                              |
| `test-author`        | Writes unit + integration + E2E tests                 |
| `tdd-guide`          | Plans the minimum test matrix before tests are written |
| `code-reviewer`      | Reviews recent code for risk / convention-match       |

Per-stack skill resolution (~137 skills total, auto-pruned at `/init-figma-compose`): see [`protocols/skills.md`](.figma-pipeline/protocols/skills.md) for the resolution table.

<details>
<summary><strong>Bundled skill catalog — 137 skills, grouped (click to expand)</strong></summary>

| Category | Count | Skills |
|---|---:|---|
| **Framework — Angular** | 13 | `adev-writing-guide`, `angular-component`, `angular-developer`, `angular-di`, `angular-directives`, `angular-forms`, `angular-http`, `angular-new-app`, `angular-routing`, `angular-signals`, `angular-ssr`, `angular-testing`, `angular-tooling` |
| **Framework — React / Next / Remix** | 11 | `next-best-practices`, `next-cache-components`, `nextjs-react-redux-typescript-cursor-rules`, `nextjs-server-components`, `react-best-practices`, `react-component-architecture`, `react-modernization`, `react-state-management`, `remix`, `vercel-react-best-practices`, `vercel-react-view-transitions` |
| **Framework — Vue / Nuxt** | 6 | `nuxtjs-vue-typescript`, `vue-best-practices`, `vue-component-patterns`, `vue-composition-api`, `vue-reactivity-system`, `vue-typescript` |
| **Framework — Svelte** | 2 | `svelte-code-writer`, `svelte-core-bestpractices` |
| **CSS — Tailwind / UnoCSS** | 9 | `tailwindcss`, `tailwindcss-development`, `tailwind-components`, `tailwind-configuration`, `tailwind-design-system`, `tailwind-performance`, `tailwind-responsive-design`, `tailwind-utility-classes`, `unocss` |
| **CSS — Other** | 6 | `css`, `frontend-css-patterns`, `postcss-best-practices`, `sass-best-practices`, `scss-best-practices`, `vanilla-extract` |
| **Design system** | 27 | `ant-design`, `antd`, `atomic-design-atoms`, `atomic-design-fundamentals`, `atomic-design-integration`, `atomic-design-molecules`, `atomic-design-organisms`, `atomic-design-quarks`, `atomic-design-templates`, `chakra-ui-builder`, `chakra-ui-migrate`, `chakra-ui-refactor`, `design-system-patterns`, `heroui-migration`, `heroui-react`, `mantine-combobox`, `mantine-custom-components`, `mantine-form`, `material-ui-nextjs`, `material-ui-styling`, `material-ui-tailwind`, `material-ui-theming`, `radix-ui-design-system`, `shadcn`, `ui-design`, `ui-design-system`, `visual-design-foundations` |
| **Testing — unit / E2E / stories** | 22 | `e2e-testing-patterns`, `javascript-testing-patterns`, `jest-advanced`, `jest-configuration`, `jest-testing-patterns`, `playwright-bdd-configuration`, `playwright-bdd-gherkin-syntax`, `playwright-bdd-step-definitions`, `playwright-cursor-rules`, `playwright-fixtures-and-hooks`, `playwright-page-object-model`, `playwright-pro`, `playwright-test-architecture`, `storybook-args-controls`, `storybook-component-documentation`, `storybook-configuration`, `storybook-play-functions`, `storybook-story-writing`, `tdd-guide`, `vitest-configuration`, `vitest-performance`, `vitest-testing-patterns` |
| **TypeScript** | 5 | `typescript`, `typescript-async-patterns`, `typescript-type-system`, `typescript-utility-types`, `zod-schema-validation` |
| **State management** | 6 | `redux-toolkit`, `zustand-advanced-patterns`, `zustand-middleware`, `zustand-state-management`, `zustand-store-patterns`, `zustand-typescript` |
| **Figma integration** | 6 | `figma-analyze-frame`, `figma-extract-tokens`, `figma-generate-component`, `figma-integration`, `figma-sync-design-system`, `figma-use` |
| **Accessibility** | 3 | `a11y-audit`, `accessibility-a11y`, `accessibility-compliance` |
| **Quality / senior roles** | 3 | `senior-frontend`, `senior-qa`, `senior-security` |
| **Cross-cutting** | 11 | `component-architecture`, `feature-arch`, `feature-sliced-design`, `modern-javascript-patterns`, `panda-css`, `responsive-design`, `solid`, `solid-react`, `styled-components-best-practices`, `vuejs-typescript-best-practices`, `web-component-design` |

Full attribution + content hashes: [`skills-lock.json`](./skills-lock.json). Per-stack resolution algorithm: [`protocols/skills.md`](.figma-pipeline/protocols/skills.md).

</details>

---

## Tool support matrix

| Capability                                  | Claude Code           | Cursor                             | Codex CLI                          |
| ------------------------------------------- | --------------------- | ---------------------------------- | ---------------------------------- |
| `/init-figma-compose` wizard                | ✅ native             | ✅ inline                          | ✅ `wrap.sh` / `./codex-run`       |
| Multi-agent pipeline                        | ✅ native `Agent`     | ✅ inline                          | ✅ `codex run-agent`               |
| MCP integration                             | ✅ `.mcp.json`        | ✅ settings UI                     | ✅ `.mcp.json`                     |
| MCP hard gate at wizard time                | ✅ programmatic auth  | ✅ user-driven + verify             | ✅ user-driven + verify (exit 3 on fail) |
| Lifecycle hooks                             | ✅ native             | ✅ `alwaysApply` rules             | ✅ via `wrap.sh`                   |
| Per-call model routing                      | ✅ `Agent(model=…)`   | ⚠ user-selected; recommendation shown | ✅ `--model`                  |
| KG / handover / complexity                  | ✅                    | ✅                                 | ✅                                 |
| Graphify `/graphify` skill registration     | ✅ `--platform claude` | ✅ `--platform cursor`            | ✅ `--platform codex` (`$graphify`) |
| RTK shell-output compression                | ✅ `rtk init -g`      | ✅ `rtk init --agent cursor`        | ✅ `rtk init -g --codex`           |

---

## Configuration

`.figma-pipeline/config.json` is the contract every agent reads. The wizard writes it; you can hand-edit, then rerun `/init-figma-compose --re-detect` to refresh the writes-allowlist. JSON Schema: [`config.schema.json`](.figma-pipeline/config.schema.json). Reference: [`config.example.json`](.figma-pipeline/config.example.json).

Key sections:

- `framework`, `language`, `cssSystem`, `designSystem`, `components`, `icons`, `tokens` — stack choices
- `stories`, `tests` — Storybook + unit + E2E
- `complexity` — tier overrides, model overrides, thresholds
- `knowledgeGraph` — enabled, storeDir, embeddings provider, retention, visual regression
- `codex.modelMap` — per-size Codex model IDs (Codex CLI only)
- `figma.mcpVerifiedAt` — ISO-8601 stamp proving MCP was reachable at wizard time
- `rtk` — `{ installed, initialized, version, detectedAt }` (read-only)
- `graphify` — `{ installed, version, outputDir, skillScope, registeredAt, installFailed }` (read-only)
- `gitignorePatch` — `{ appliedAt, entriesAdded }` audit
- `tools` (+ `tools.codexShortcut` when Codex enabled) — wired AI tools
- `writeScope.allowedDirs` — derived; enforced by `check-frozen-paths.sh`

---

## Repo layout

| Path                                                 | Purpose                                                                                |
| ---------------------------------------------------- | -------------------------------------------------------------------------------------- |
| `.figma-pipeline/config.json`                        | Single source of truth — written by `/init-figma-compose` only after the MCP hard gate passes |
| `.figma-pipeline/protocols/`                         | Tool-neutral data contracts (manifest, knowledge-graph, complexity, handover, cli, skills, allowlist, token-strategy, component-layout) |
| `.figma-pipeline/adapters/{frameworks,css,design-systems}/` | Per-stack code-generation templates                                              |
| `.figma-pipeline/skills/`                            | Canonical skill catalog (~137 skills, auto-pruned by the wizard)                       |
| `.figma-pipeline/kg/`                                | Knowledge graph data (created on first build)                                          |
| `.claude/agents/` `commands/` `hooks/`               | Claude Code surface                                                                    |
| `.cursor/prompts/` `rules/`                          | Cursor surface (mirrors of agents + hooks)                                             |
| `.codex/agents/` `commands/` `hooks/` `wrap.sh`      | Codex CLI surface + lifecycle simulator                                                |
| `<projectRoot>/codex-run`                            | Executable wrapper, only when Codex CLI enabled                                        |
| `<projectRoot>/.gitignore`                           | Patched (idempotent marker block) on every wizard run                                  |
| `<projectRoot>/graphify-out/`                        | Built by you via `/graphify .` — not by the wizard. Gitignored.                        |

---

## Credits — bundled skills

137 skills under `.figma-pipeline/skills/` curated from the open-source community. Each retains its original `SKILL.md` with attribution preserved. Source repos + content hashes tracked in [`skills-lock.json`](./skills-lock.json). Main contributors: [thebushidocollective/han](https://github.com/thebushidocollective/han) (44), [mindrally/skills](https://github.com/mindrally/skills) (20), [wshobson/agents](https://github.com/wshobson/agents) (10), [analogjs/angular-skills](https://github.com/analogjs/angular-skills) (10), [alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills) (7), plus DS-specific bundles from Material UI, Chakra, Mantine, Hero UI, Next.js, Svelte, Vercel Labs, and Angular core teams. Full attribution in `skills-lock.json`. Open an issue if you'd like a skill renamed, relinked, or removed.

---

## License

**MIT** — see [LICENSE](./LICENSE). Bundled third-party skills retain their original licenses; consult each skill's upstream `LICENSE` before redistributing in isolation.

---

## Links

- **Repo**: [github.com/raveracker/figma-code-composer](https://github.com/raveracker/figma-code-composer)
- **npm**: [`figma-code-composer`](https://www.npmjs.com/package/figma-code-composer)
- **Issues**: [github.com/raveracker/figma-code-composer/issues](https://github.com/raveracker/figma-code-composer/issues)
- **Binding rules**: [`CLAUDE.md`](./CLAUDE.md) · [`AGENTS.md`](./AGENTS.md)
- **Protocols** (source of truth for agent behavior): [`.figma-pipeline/protocols/`](./.figma-pipeline/protocols/)
