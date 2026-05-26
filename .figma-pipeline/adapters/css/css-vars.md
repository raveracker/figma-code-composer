# CSS vars (vanilla) adapter

## When to use
`config.cssSystem.name == "css-vars"`. Project uses plain `.css` with custom properties + class selectors. No build tooling for utilities.

## Token emission

Strategy: `css-custom-properties`. Emit per-category files:

```css
/* {{tokens.outputDir}}/colors.css */
:root {
  --color-brand-primary: #FF6E1D;
  --color-surface-bg: #FFFFFF;
}

[data-theme="dark"] {
  --color-surface-bg: #0A0A0A;
}
```

```css
/* {{tokens.outputDir}}/spacing.css */
:root {
  --space-1: 0.25rem;
  --space-2: 0.5rem;
}
```

Index file imports all categories:

```css
/* {{tokens.outputDir}}/index.css */
@import "./colors.css";
@import "./spacing.css";
@import "./radius.css";
@import "./typography.css";
```

## Component class attachment

Component-builder emits one stylesheet per component, classes referenced as global selectors:

```css
/* {{componentDir}}/{{Name}}/{{Name}}.css */
.app-{{kebabName}} {
  background: var(--color-brand-primary);
  padding: var(--space-1);
}

.app-{{kebabName}}--size-sm { padding: var(--space-1); }
.app-{{kebabName}}--disabled { opacity: 0.5; cursor: not-allowed; }
```

Component imports its CSS once (in React: at top of the component file). Class names referenced as plain strings.

## Custom token registration

Not applicable.

## Gotchas
- **Global namespace**: no isolation. Pick a project-wide prefix (`app-`) and stick to it; emit a flag if the component-builder generates a class colliding with a non-prefixed selector.
- **Specificity**: `[data-theme]` on `<html>` cascades; state selectors (`:hover`, `:focus-visible`, `:disabled`) need careful ordering inside the stylesheet.
- **Build deduplication**: importing the same token stylesheet from many components is fine in modern bundlers (they dedupe), but in plain HTML, link it once in `<head>`.
