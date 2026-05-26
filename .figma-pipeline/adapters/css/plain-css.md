# Plain CSS adapter

## When to use
`config.cssSystem.name == "plain-css"`. Project has `.css` files imported normally; no preprocessor, no utility framework, no modules.

## Token emission

Strategy: `css-custom-properties`. Single emitted file by default:

```css
/* {{tokens.outputDir}}/tokens.css */
:root {
  --color-brand-primary: #FF6E1D;
  --color-surface-bg: #FFFFFF;
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --radius-sm: 0.25rem;
}

[data-theme="dark"] {
  --color-surface-bg: #0A0A0A;
}
```

Include in app entry (`<link>` in HTML or `import "./tokens.css"` in JS).

## Component class attachment

Same pattern as `css-vars`. Component-builder writes a sibling `.css` file per component, classes referenced as global strings.

## Custom token registration

Not applicable.

## Gotchas
- **No build help**: no autoprefixer / no minification unless the project explicitly adds PostCSS. The agent's emitted CSS should be modern-browser-safe (no IE) but avoid bleeding-edge features unless `framework.version` suggests modern targets.
- **Stylesheet ordering**: token file must load BEFORE component files; component-builder must check the project's load order before emitting.
- **The wizard's migration offer**: when the user starts on `plain-css` and confirms migration intent, the chosen target system's adapter takes over (see `migration-architect` skill).
