# Stitches adapter

## When to use
`config.cssSystem.name == "stitches"`. Runtime-flexible CSS-in-JS (now archived upstream — accept-but-warn).

## Token emission

Strategy: `js-tokens`. Patch `stitches.config.ts`:

```ts
// stitches.config.ts
import { createStitches } from "@stitches/react";

export const { styled, css, theme, createTheme, globalCss, getCssText } = createStitches({
  theme: {
    colors: {
      brandPrimary: "#FF6E1D",
      brandSecondary: "#1A1A1A",
      surfaceBg: "#FFFFFF"
    },
    space: { 1: "0.25rem", 2: "0.5rem" },
    radii: { sm: "0.25rem" }
  }
});

export const darkTheme = createTheme({
  colors: {
    brandPrimary: "#FF8A4A",
    surfaceBg: "#0A0A0A"
  }
});
```

Apply theme via `<html className={darkTheme}>` or similar.

## Component class attachment

```tsx
import { styled } from "../../stitches.config";

export const Root = styled("div", {
  background: "$brandPrimary",
  padding: "$1",
  borderRadius: "$sm",
  variants: {
    size: {
      sm: { padding: "$1" },
      md: { padding: "$2" }
    },
    disabled: { true: { opacity: 0.5, cursor: "not-allowed" } }
  }
});
```

## Custom token registration

Not applicable.

## Gotchas
- **Archived upstream** (as of mid-2024): adapter emits a one-time warning during the wizard suggesting migration to `vanilla-extract` or `panda`. The user can dismiss.
- **No SSR streaming**: `getCssText()` is sync only; works in Next.js `pages` directory but not in App Router RSC streaming. Surface a flag for App Router projects.
- **`$<token>` syntax**: Stitches uses `$brandPrimary` (no dot) instead of `theme.colors.brandPrimary`. Component-builder uses `$` form.
