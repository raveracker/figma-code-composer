# UnoCSS adapter

## When to use
`config.cssSystem.name == "unocss"`.

## Token emission

Strategy: `unocss-theme`. Patch the project's `uno.config.{ts,js}`:

```ts
// uno.config.ts (existing, patched)
import { defineConfig, presetUno, presetIcons } from "unocss";

export default defineConfig({
  presets: [presetUno(), presetIcons()],
  theme: {
    colors: {
      brand: {
        primary: "#FF6E1D",
        secondary: "#1A1A1A"
      }
    },
    spacing: {
      1: "0.25rem"
    },
    borderRadius: {
      sm: "0.25rem"
    }
  }
});
```

Token-builder ONLY patches `theme.*` (never `presets`, `shortcuts`, or `rules`).

## Component class attachment

Same as Tailwind utility classes: `bg-brand-primary`, `text-white`, `gap-2`, etc.

## Custom token registration

UnoCSS doesn't have a tailwind-merge equivalent. For dynamic classes, add to `safelist`:

```ts
export default defineConfig({
  safelist: ["bg-brand-primary", "bg-brand-secondary", ...]
});
```

Token-builder should append to `safelist` when emitting tokens that may be referenced via dynamic class composition.

## Gotchas
- **Presets are not theme**: a `colors` key under `theme` extends; under a preset is replaced. Token-builder always writes to top-level `theme`.
- **`shortcuts`**: design-system idiom in UnoCSS world is to use `shortcuts` for composed utilities. Token-builder doesn't emit shortcuts — component-builder uses raw utilities only to keep behaviour consistent across CSS systems.
- **Inline mode** (`@unocss/runtime`): not supported by this adapter — UnoCSS must be a build-time integration.
