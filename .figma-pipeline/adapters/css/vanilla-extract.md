# vanilla-extract adapter

## When to use
`config.cssSystem.name == "vanilla-extract"`. TS-first CSS-in-JS with build-time extraction.

## Token emission

Strategy: `js-tokens`. Emit `.css.ts`:

```ts
// {{tokens.outputDir}}/theme.css.ts
import { createGlobalTheme, createThemeContract } from "@vanilla-extract/css";

export const tokens = createThemeContract({
  color: {
    brandPrimary: null,
    surfaceBg: null
  },
  space: { _1: null, _2: null },
  radius: { sm: null, md: null }
});

createGlobalTheme(":root", tokens, {
  color: { brandPrimary: "#FF6E1D", surfaceBg: "#FFFFFF" },
  space: { _1: "0.25rem", _2: "0.5rem" },
  radius: { sm: "0.25rem", md: "0.5rem" }
});

// dark mode
createGlobalTheme('[data-theme="dark"]', tokens, {
  color: { brandPrimary: "#FF8A4A", surfaceBg: "#0A0A0A" },
  // … same shape, different values
});
```

(Numeric keys like `1`, `2` aren't valid JS identifiers → emit as `_1`, `_2` and document the mapping.)

## Component class attachment

```ts
// {{Name}}.css.ts
import { style } from "@vanilla-extract/css";
import { tokens } from "../../tokens/theme.css";

export const root = style({
  background: tokens.color.brandPrimary,
  padding: tokens.space._1,
  borderRadius: tokens.radius.sm,
});

export const sizeSm = style({ padding: tokens.space._1 });
export const sizeMd = style({ padding: tokens.space._2 });
```

```tsx
// {{Name}}.tsx
import { root, sizeSm, sizeMd } from "./{{Name}}.css";
<div className={`${root} ${size === "sm" ? sizeSm : sizeMd}`}>
```

## Custom token registration

Not applicable.

## Gotchas
- **Build integration**: requires vite/webpack plugin. Adapter fails closed if `@vanilla-extract/vite-plugin` (or webpack equivalent) isn't in `devDependencies`.
- **Contracts vs themes**: `createThemeContract` declares the shape; `createGlobalTheme` (or `createTheme`) fills it. Token-builder uses the contract pattern for clean multi-theme support.
- **Numeric tokens**: JS can't use `1` as a key — pick a prefix (`_1`) or convert to `size1`.
