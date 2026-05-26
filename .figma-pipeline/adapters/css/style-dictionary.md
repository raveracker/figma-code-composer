# Style Dictionary adapter

## When to use
`config.cssSystem.name == "style-dictionary"`. Project uses Amazon's Style Dictionary as the source-of-truth token store with platform-specific transforms.

## Token emission

Strategy: `style-dictionary-json`. Emit DTCG-compliant JSON:

```jsonc
// {{tokens.outputDir}}/color.json
{
  "color": {
    "brand": {
      "primary": { "value": "#FF6E1D", "type": "color" },
      "secondary": { "value": "#1A1A1A", "type": "color" }
    },
    "surface": {
      "bg": {
        "value": "{color.neutral.100}",
        "type": "color"
      }
    }
  }
}
```

```jsonc
// {{tokens.outputDir}}/space.json
{
  "space": {
    "1": { "value": "0.25rem", "type": "spacing" },
    "2": { "value": "0.5rem", "type": "spacing" }
  }
}
```

Multi-mode: emit `color.light.json` + `color.dark.json` etc. and let SD transforms produce the platform output.

## Component class attachment

SD's output drives whichever target platform the project compiles to (CSS vars, JS object, iOS, Android). Component-builder reads the project's `style-dictionary.config.{js,json}` to learn the chosen platform, then emits CSS/JS that references the build output.

Typical CSS-vars target → behaves like `css-vars` adapter from the component's POV.

## Custom token registration

Not applicable to the JSON sources. Platform transforms decide output naming.

## Gotchas
- **DTCG vs legacy**: SD v4 supports DTCG (`$value`, `$type`). v3 uses `value`, `type`. Adapter emits DTCG by default; downgrade if `package.json` pins `style-dictionary@3`.
- **Reference syntax**: `{color.brand.primary}` (curly braces). NOT `var(--color-brand-primary)`.
- **Transform pipeline**: SD applies transforms in order. Custom transforms (e.g. case conversion) live in `style-dictionary.config.js` and are project-owned — token-builder doesn't touch them.
- **No runtime theming**: SD is build-time. For runtime mode switching, emit multiple platform builds and let the consumer load them conditionally.
