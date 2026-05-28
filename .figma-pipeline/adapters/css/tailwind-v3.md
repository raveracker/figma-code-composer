# Tailwind v3 adapter

## When to use
`config.cssSystem.name == "tailwind-v3"`. Requires `tailwind.config.{js,ts,cjs,mjs}` in the project root.

## Token emission

Strategy: `js-tokens`. Emit a TS object the consumer extends `theme` from:

```ts
// {{tokens.outputDir}}/tokens.ts
export const tokens = {
  colors: {
    brand: {
      primary: "#FF6E1D",
      secondary: "#1A1A1A"
    }
  },
  spacing: {
    1: "0.25rem",
    2: "0.5rem"
  },
  borderRadius: {
    sm: "0.25rem",
    md: "0.5rem"
  }
} as const;
```

Token-builder also patches the project's `tailwind.config` (additive only — never replaces) to spread `tokens` into `theme.extend`:

```js
// tailwind.config.js (existing, patched)
const { tokens } = require("./src/styles/tokens/tokens");

module.exports = {
  content: ["./src/**/*.{ts,tsx,vue,svelte,html}"],
  theme: {
    extend: {
      colors: tokens.colors,
      spacing: tokens.spacing,
      borderRadius: tokens.borderRadius
    }
  }
};
```

Theming (multi-mode): emit one constant per mode + a JS theme-switch helper, OR use `darkMode: "class"` and a single tokens object with `dark:` variants on consuming components.

## Component class attachment

Standard Tailwind classes. No prefix (unless `prefix` is set in the project's tailwind config — then component-builder respects it).

```tsx
<div className="flex items-center gap-2 bg-brand-primary text-white">
```

## Custom token registration

`tailwind-merge` v2.x understands most custom theme extensions automatically. For exotic group names, configure via `extendTailwindMerge` same as v4.

## Gotchas
- **Spacing scale is BOUNDED (unlike v4).** v3's default spacing/sizing scale is a fixed set (`0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 5, 6, 8, 10, …`), so the v4 trick of `px ÷ 4 → <utility>-<n>` for ANY `n` does **not** hold — `w-46` isn't a default v3 class. So: if the px value maps to an existing scale step (or a `theme.extend.spacing` entry the token-builder added), use that utility; otherwise an arbitrary `w-[184px]` bracket is acceptable in v3 (a dev can hand-fix or the value can be added to `theme.extend.spacing`). Don't trigger `/figma-update` just to tidy a bracket. (Contrast `adapters/css/tailwind-v4.md` § Gotchas, where the dynamic scale makes `w-46` valid.)
- **`theme` vs `theme.extend`**: `theme` REPLACES Tailwind defaults; `theme.extend` ADDS. Token-builder always uses `extend`.
- **Content paths**: token-builder must NOT modify the `content` array; that's project-owned.
- **JIT vs AOT**: v3 is JIT by default. Dynamic class names (`bg-${color}`) DON'T work — emit static class lists only.
