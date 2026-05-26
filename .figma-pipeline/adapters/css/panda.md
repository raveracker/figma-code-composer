# Panda CSS adapter

## When to use
`config.cssSystem.name == "panda"`. Chakra's spiritual successor; type-safe CSS-in-JS with build-time extraction.

## Token emission

Strategy: `js-tokens`. Patch `panda.config.ts`:

```ts
// panda.config.ts (existing, patched)
import { defineConfig, defineTokens, defineSemanticTokens } from "@pandacss/dev";

const tokens = defineTokens({
  colors: {
    brand: {
      primary: { value: "#FF6E1D" },
      secondary: { value: "#1A1A1A" }
    }
  },
  spacing: { 1: { value: "0.25rem" } },
  radii: { sm: { value: "0.25rem" } }
});

const semanticTokens = defineSemanticTokens({
  colors: {
    surface: {
      bg: {
        value: { base: "{colors.neutral.100}", _dark: "{colors.neutral.900}" }
      }
    }
  }
});

export default defineConfig({
  preflight: true,
  include: ["./src/**/*.{ts,tsx,vue,svelte}"],
  theme: { tokens, semanticTokens }
});
```

Multi-mode is built-in via `_dark` / `_light` conditions.

## Component class attachment

```tsx
import { css } from "../../styled-system/css";

<div className={css({
  bg: "brand.primary",
  p: "1",
  rounded: "sm"
})}>
```

`recipe()` for cva-style variants is preferred for design-system components:

```ts
import { cva } from "../../styled-system/css";

export const buttonRecipe = cva({
  base: { px: "4", py: "2", rounded: "md" },
  variants: {
    size: {
      sm: { px: "2", py: "1" },
      md: { px: "4", py: "2" }
    }
  }
});
```

## Custom token registration

Not applicable — Panda's compiler tracks every reference.

## Gotchas
- **`panda codegen`**: must run after token changes. Token-builder emits a hint to run `panda codegen` (or auto-runs via `npx panda codegen` if available).
- **Static extraction**: dynamic class composition (`bg: dynamic ? "a" : "b"`) works when both sides are static. Truly dynamic values must use CSS vars.
- **Preflight**: Panda's reset. Don't disable unless intentional.
