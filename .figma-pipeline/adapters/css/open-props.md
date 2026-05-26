# Open Props adapter

## When to use
`config.cssSystem.name == "open-props"`.

## Token emission

Strategy: `css-custom-properties`. Emit CSS files with `:root { --…: …; }` blocks alongside the standard Open Props set:

```css
/* {{tokens.outputDir}}/props.css */
@import "open-props/style";

:root {
  --color-brand-primary: #FF6E1D;
  --color-brand-secondary: #1A1A1A;
  --space-app-1: 0.25rem;
  --radius-app-sm: 0.25rem;
}

[data-theme="dark"] {
  --color-brand-primary: #FF8A4A;
}
```

Prefix `--app-` recommended (`tokens.prefix`) to avoid colliding with `--brand-*` from Open Props if both exist.

## Component class attachment

Open Props gives you CSS vars, NOT utility classes. The component-builder emits standard CSS class names and a per-component stylesheet:

```css
/* in component .module.css or scoped <style> */
.root {
  background: var(--color-brand-primary);
  padding: var(--space-app-2);
  border-radius: var(--radius-app-sm);
}
```

For utility-class workflow, pair Open Props with a utility lib like Tachyons, Pollen, or roll your own utility layer.

## Custom token registration

Not applicable — CSS vars don't need registration.

## Gotchas
- **No utility classes out of the box**: don't expect Tailwind-style `bg-brand-primary` — you write classes that consume vars.
- **Cascading**: vars inherit through the DOM, so `[data-theme="dark"]` on `<html>` cascades. Component-level overrides also work.
- **Open Props naming**: their props (`--blue-7`, `--size-3`) coexist with yours. Pick a prefix or scope to avoid collisions.
