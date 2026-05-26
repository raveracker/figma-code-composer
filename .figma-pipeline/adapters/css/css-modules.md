# CSS Modules adapter

## When to use
`config.cssSystem.name == "css-modules"`. Project uses `*.module.css` (or `.scss`) imports.

## Token emission

Strategy: `css-custom-properties`. Tokens are global — emit to a non-module stylesheet:

```css
/* {{tokens.outputDir}}/tokens.css */
:root {
  --color-brand-primary: #FF6E1D;
  --space-1: 0.25rem;
}

[data-theme="dark"] {
  --color-brand-primary: #FF8A4A;
}
```

Import once at the app entry (`main.tsx` / `App.tsx`). CSS Modules CANNOT define globals — they MUST live in plain `.css`.

## Component class attachment

Per-component module:

```css
/* {{Name}}.module.css */
.root {
  background: var(--color-brand-primary);
  padding: var(--space-1);
}

.root:hover {
  background: var(--color-brand-primary-hover);
}
```

Component-builder generates a one-class-per-state module, with variant suffixes:

```css
.root { ... }
.root--size-sm { padding: var(--space-1); }
.root--size-md { padding: var(--space-2); }
.root--disabled { opacity: 0.5; }
```

Consumer uses imported `styles`:

```tsx
import styles from "./{{Name}}.module.css";
<div className={`${styles.root} ${styles[`root--size-${size}`]}`}>
```

## Custom token registration

Not applicable.

## Gotchas
- **Class composition**: `composes` keyword in CSS Modules can pull in other classes. Use sparingly — it inverts the dependency direction.
- **`:global(...)`**: needed to target non-module selectors (e.g. `[data-theme]`). Wrap state selectors that depend on global attrs.
- **Naming**: CSS Modules hash class names. Don't rely on the unhashed name in JS — always import via `styles.foo`.
