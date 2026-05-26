# Sass / SCSS adapter

## When to use
`config.cssSystem.name == "sass"`. Project uses SCSS-style imports + variables.

## Token emission

Strategy: `scss-variables` + matching CSS vars (modern Sass best practice — both available).

```scss
/* {{tokens.outputDir}}/_tokens.scss */
@use "sass:map";

$tokens: (
  color: (
    brand-primary: #FF6E1D,
    surface-bg: #FFFFFF
  ),
  space: (1: 0.25rem, 2: 0.5rem),
  radius: (sm: 0.25rem, md: 0.5rem)
);

@function token($category, $name) {
  @return map.get(map.get($tokens, $category), $name);
}

@mixin theme($mode) {
  @if $mode == "default" {
    --color-brand-primary: #{token(color, brand-primary)};
  } @else if $mode == "dark" {
    --color-brand-primary: #FF8A4A;
  }
}

:root { @include theme("default"); }
[data-theme="dark"] { @include theme("dark"); }
```

Consumers `@use "tokens" as t;` then `background: t.token(color, brand-primary);` OR consume CSS vars directly.

## Component class attachment

Component .scss file with nested selectors:

```scss
/* {{Name}}.component.scss */
@use "../../tokens" as t;

.app-{{kebab-name}} {
  background: var(--color-brand-primary);
  padding: t.token(space, 1);
  border-radius: t.token(radius, sm);

  &--size-md { padding: t.token(space, 2); }
  &--disabled { opacity: 0.5; pointer-events: none; }

  &:hover { background: var(--color-brand-primary-hover); }
}
```

## Custom token registration

Not applicable.

## Gotchas
- **`@import` vs `@use`**: `@import` is deprecated; `@use` is namespaced. Token-builder emits `@use`.
- **CSS vars + SCSS vars**: prefer CSS vars for runtime-switchable values (theming); SCSS for compile-time-only values (breakpoints, mixin args).
- **Dart Sass vs LibSass**: only Dart Sass (`sass` package) supports modern `@use`. Reject LibSass detection.
