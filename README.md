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
| Story + test gen   | Storybook / Histoire / Ladle CSF3 + Vitest / Jest / Karma / Playwright tests              |
| Design-system mode | Optional: emit Braid / Chakra / Mantine / MUI / Radix / shadcn / Headless UI primitives instead of plain HTML + classes |

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
4. **Design system (optional)** — Braid / Chakra / Mantine / MUI / Radix / shadcn / Headless UI / none
5. **Design methodology + CSS choice** — atomic / feature-sliced / layered / hexagonal / flat, plus a CSS framework
6. **Write paths** — where components, tokens, icons, stories, and tests live

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

## Frameworks, CSS systems & design systems supported

**Frameworks:** React (incl. Next.js, Vite) · Vue 3 · Angular · Svelte · Solid · Lit · Alpine
**CSS systems:** Tailwind v4 · Tailwind v3 · UnoCSS · Open Props · vanilla CSS-vars · CSS Modules · Sass · Style Dictionary · plain `.css` · vanilla-extract · Panda · Stitches
**Design systems** (optional, override component shape): **Braid** (SEEK) · Chakra UI · Mantine · MUI · Radix · shadcn/ui · Headless UI · _none / custom_
**Design methodologies:** Atomic Design · Feature-Sliced · Layered · Hexagonal · Flat / custom

When a design system is selected, `component-builder`, `story-author`, `test-author`, `token-builder`, and `icon-generator` all consult `.figma-pipeline/adapters/design-systems/<name>.md` and may override their framework / CSS-system defaults — see `.figma-pipeline/config.braid.example.json` for a Braid-on-Next.js example.

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
