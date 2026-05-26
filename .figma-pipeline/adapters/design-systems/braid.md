# Braid Design System adapter

> [Braid](https://seek-oss.github.io/braid-design-system/) — SEEK's production React design system. TypeScript-first, vanilla-extract internally, multi-brand theming.

## When to use
`config.designSystem.name == "braid"`. Requires `framework.name == "react"`. Tested against `braid-design-system@33+`.

## Dependencies

```json
// package.json (consumer installs)
{
  "dependencies": {
    "braid-design-system": "^33.0.0",
    "@vanilla-extract/css": "^1.15.0",
    "react": "^18.0.0",
    "react-dom": "^18.0.0"
  }
}
```

## Theme

Braid ships its own themes. `config.designSystem.themeName` picks one — wizard prompts for it:

| `themeName`            | Audience                                  |
| ---------------------- | ----------------------------------------- |
| `apacBlue`             | SEEK APAC (SEEK Asia, SEEK Australia)     |
| `apacGreen`            | SEEK APAC alt                              |
| `catho`                | Catho (Brazil)                            |
| `docs`                 | Internal docs                             |
| `jobsDb`               | JobsDB                                    |
| `jobStreet`            | JobStreet                                 |
| `seekAnz`              | SEEK ANZ (default)                        |
| `seekBusiness`         | SEEK Business                             |
| `seekJobs`             | SEEK Jobs                                 |
| `seekUnifiedBeta`      | SEEK Unified beta                         |
| `wireframe`            | Greybox / wireframe                       |

Custom themes: Braid supports `customTheme.fromMetrics(...)` — wizard records `themeName: "custom"` and the user wires it manually.

## App-shell setup

The component-builder ensures the consumer app is wrapped in `BraidProvider`. Emitted to `src/AppProviders.tsx` (or merges into an existing provider tree):

```tsx
import { BraidProvider } from "braid-design-system";
import braidTheme from "braid-design-system/themes/seekAnz";
import "braid-design-system/reset"; // optional but recommended
import type { ReactNode } from "react";

export function AppProviders({ children }: { children: ReactNode }) {
  return <BraidProvider theme={braidTheme}>{children}</BraidProvider>;
}
```

## Token mapping (Figma → Braid)

Braid owns its tokens — the figma-pipeline does NOT emit Braid tokens (treat Braid tokens as immutable; project-specific overrides happen via the Braid theme metric API, not via the figma-pipeline). The token-builder's behaviour shifts:

| Figma variable category           | Braid mapping                                                              |
| --------------------------------- | -------------------------------------------------------------------------- |
| Colors marked semantic (`surface/bg`, `text/primary`, …) | Drop into Braid's nearest equivalent (`background="surface"`, `tone="secondary"`); record any unmapped color as a flag |
| Colors marked primitive           | Skip — emit a flag suggesting use of Braid's tone system instead           |
| Spacing                           | Map to Braid's `space` scale: `xxsmall`/`xsmall`/`small`/`medium`/`large`/… (round to nearest) |
| Border radius                     | Map to `borderRadius`: `none`/`standard`/`large`/`xlarge`/`full`           |
| Typography                        | Map to `text` size/weight/tone props (`<Text size="standard" tone="neutral" weight="strong">`) |
| Anything unmappable               | Record as a flag — never inline a hex/rem inside a Braid component         |

`token-builder` writes a small mapping table to `<tokens.outputDir>/braid-map.json` and does NOT emit any CSS. If the user wants to extend Braid theming, the wizard surfaces a follow-up question.

## Component mapping (component-builder)

When Braid is active, emit Braid components — NOT HTML primitives + classes:

| Pattern                              | Plain HTML emit                                  | Braid emit                                                                     |
| ------------------------------------ | ------------------------------------------------ | ------------------------------------------------------------------------------ |
| Layout container                     | `<div className="flex …">`                       | `<Box>` / `<Stack>` / `<Inline>` / `<Columns>` / `<Tiles>`                     |
| Spacing                              | `padding`, `gap` utility classes                  | `<Box padding="medium" />`, `<Stack space="small" />`                          |
| Text                                 | `<p className="text-base text-neutral">`         | `<Text size="standard" tone="neutral">…</Text>`                                 |
| Heading                              | `<h1>`/`<h2>`                                    | `<Heading level="1">…</Heading>`                                                |
| Buttons                              | `<button>`                                       | `<Button tone="brandAccent">…</Button>`                                         |
| Inputs                               | `<input>`                                        | `<TextField id="…" label="…" />`                                                |
| Cards                                | `<div className="rounded-lg shadow …">`          | `<Card>` (rare — composes from `Box`)                                            |
| Notice / Alert                       | Custom div                                       | `<Notice tone="critical|positive|info">…</Notice>`                              |
| Modal                                | Headless modal lib                               | `<Dialog id="…" title="…">…</Dialog>`                                            |
| Icons                                | Inline SVG                                       | Braid's own `<IconArrow />` etc. when available; otherwise emit as a child SVG  |

**Atomic-Design mapping (when `designMethodology == "atomic"`)**:

- **Atom** — Braid leaf components (`Text`, `Heading`, `Button`, `TextLink`, `Box`).
- **Molecule** — composed Braid primitives (`<Stack>` of inputs, search affordances) wrapped in a named component.
- **Organism** — page sections built from molecules; still Braid-native.
- **Template / page** — full page layouts via `<PageBlock>`, `<ContentBlock>`.

## File template

```tsx
// src/components/molecules/SearchHeader/SearchHeader.tsx
import { Stack, Heading, Text, TextField, Button, Box } from "braid-design-system";
import type { ReactNode } from "react";

export interface SearchHeaderProps {
  title: string;
  description?: ReactNode;
  onSearch: (query: string) => void;
}

export function SearchHeader({ title, description, onSearch }: SearchHeaderProps) {
  return (
    <Box padding="gutter">
      <Stack space="medium">
        <Heading level="2">{title}</Heading>
        {description && <Text tone="secondary">{description}</Text>}
        <TextField id="query" label="What" onChange={(e) => onSearch(e.target.value)} />
        <Button tone="brandAccent">Search</Button>
      </Stack>
    </Box>
  );
}
```

**Rules**:

- No `className` props on Braid components — they don't accept one. Layout via `Box` props (`padding`, `margin`, `background`, `borderRadius`, `display`).
- No inline `style={{ … }}` — Braid forbids it for design-token discipline.
- For escape-hatch styling (rare): use Braid's `<Inline>` / `<Columns>` / responsive props or compose a custom Box.

## Story idiom

```tsx
// SearchHeader.stories.tsx
import type { Meta, StoryObj } from "@storybook/react";
import { BraidProvider } from "braid-design-system";
import braidTheme from "braid-design-system/themes/seekAnz";
import { SearchHeader } from "./SearchHeader";

const meta = {
  title: "Components/Molecules/SearchHeader",
  component: SearchHeader,
  tags: ["autodocs"],
  parameters: {
    design: { type: "figma", url: "{{figmaDesignUrl}}" },
    a11y: { test: "error" }
  },
  decorators: [
    (Story) => (
      <BraidProvider theme={braidTheme}>
        <Story />
      </BraidProvider>
    )
  ],
  argTypes: {
    title: { control: "text" },
    description: { control: "text" },
    onSearch: { action: "search" }
  },
  args: { title: "Find your next role" }
} satisfies Meta<typeof SearchHeader>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {};
export const WithDescription: Story = { args: { description: "Search across 200,000 listings." } };
```

`story-author` MUST add the BraidProvider decorator on every story file. Without it, components render unstyled and a11y tests fail.

## Test idiom

```tsx
// SearchHeader.test.tsx
import { describe, it, expect, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { BraidProvider } from "braid-design-system";
import braidTheme from "braid-design-system/themes/seekAnz";
import { SearchHeader } from "./SearchHeader";

const renderWithBraid = (ui: React.ReactElement) =>
  render(<BraidProvider theme={braidTheme}>{ui}</BraidProvider>);

describe("SearchHeader", () => {
  it("renders title + search affordance", () => {
    renderWithBraid(<SearchHeader title="Find a role" onSearch={() => {}} />);
    expect(screen.getByRole("heading", { name: /find a role/i })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /search/i })).toBeInTheDocument();
  });

  it("calls onSearch as user types", async () => {
    const onSearch = vi.fn();
    renderWithBraid(<SearchHeader title="Find a role" onSearch={onSearch} />);
    await userEvent.type(screen.getByLabelText(/what/i), "engineer");
    expect(onSearch).toHaveBeenCalled();
  });
});
```

`test-author` MUST wrap every render in `BraidProvider` (or expose a `renderWithBraid` helper).

## Icon mapping (icon-generator)

Braid ships a small set of icons (`IconArrow`, `IconSearch`, `IconLocation`, etc.). Behaviour:

1. For every icon in the manifest, check if Braid ships an equivalent (`braid-design-system/icons` listing). If yes, the icon-generator emits a re-export instead of a new SVG file:

   ```ts
   // src/icons/Search.tsx
   export { IconSearch as Search } from "braid-design-system";
   ```

2. If Braid does NOT ship it, emit a regular React SVG component (per the React framework adapter) — but wrap it for sizing consistency:

   ```tsx
   // src/icons/CustomThing.tsx
   import { Box } from "braid-design-system";
   import type { ComponentProps } from "react";
   export function CustomThing(props: ComponentProps<"svg">) {
     return (
       <Box display="inline-block" component="span">
         <svg viewBox="0 0 24 24" fill="currentColor" {...props}>{/* …paths… */}</svg>
       </Box>
     );
   }
   ```

3. The icon ledger records `braidNative: true` in a new column for Braid-shipped icons.

## Token-builder behaviour

- Strategy override: `tokens.strategy` is ignored when `designSystem.name == "braid"` — Braid owns the token surface.
- The token-builder emits ONE file: `<tokens.outputDir>/braid-map.json`, mapping each Figma variable to its Braid equivalent (or `null` if unmapped). Acts as a reference for the team — not consumed at runtime.
- Custom theme extension: if the user picked `themeName: "custom"` in `/init`, the token-builder writes a starter `<tokens.outputDir>/customTheme.ts` using Braid's `themeFromMetrics`:

  ```ts
  import { themeFromMetrics } from "braid-design-system/themeFromMetrics";

  export const customTheme = themeFromMetrics({
    name: "{{projectName}}",
    brandAccent: { lightMode: "{{Figma brand color}}", darkMode: "{{Figma brand color dark}}" },
    formAccent:  { lightMode: "{{...}}", darkMode: "{{...}}" },
    // …populate from the Figma manifest where the mapping is unambiguous;
    // leave unmapped slots as TODO comments for the user to fill in.
  });
  ```

## Gotchas

- **`className` is ignored on Braid components.** Component-builder MUST refuse to emit `className` on `<Box>`, `<Stack>`, `<Text>`, etc. — emit a flag if a Figma node's style cannot be expressed via Braid props.
- **No inline `style`.** Same reason as `className`. Use Box layout props.
- **`@vanilla-extract/css` build step required.** Braid emits CSS via vanilla-extract; the consumer's bundler must integrate it (`@vanilla-extract/vite-plugin`, etc.).
- **Color tone, not literal.** Braid uses `tone="critical|positive|caution|info|secondary|neutral|brandAccent|formAccent"`. Component-builder must map Figma colors to tones — never inline hex.
- **Spacing scale is finite.** `xxsmall`/`xsmall`/`small`/`medium`/`large`/`xlarge`/`xxlarge`/`gutter`/`none`. Round to the nearest; never emit pixel-precise spacing.
- **Storybook decorators are mandatory.** Without `BraidProvider`, all components render empty.
- **Icons via Braid > custom.** Always prefer Braid's icons when one exists.
- **No React Server Components.** Braid is client-only — every Braid consumer in a Next.js App Router project needs `"use client"` at the file top.
