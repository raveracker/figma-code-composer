# CSS-system adapters

Each adapter tells `token-builder` how to emit tokens and `component-builder` how to attach styles for one CSS system. Loaded by adapter name (`adapters/css/<cssSystem.name>.md`); absent → fall back to `css-custom-properties` strategy and warn.

| File                      | CSS system         | Status     |
| ------------------------- | ------------------ | ---------- |
| `tailwind-v4.md`          | Tailwind CSS v4    | ✅ Complete |
| `tailwind-v3.md`          | Tailwind CSS v3    | ✅ Complete |
| `unocss.md`               | UnoCSS             | ✅ Complete |
| `open-props.md`           | Open Props         | ✅ Complete |
| `css-modules.md`          | CSS Modules        | ✅ Complete |
| `css-vars.md`             | Vanilla CSS vars   | ✅ Complete |
| `sass.md`                 | Sass / SCSS        | ✅ Complete |
| `style-dictionary.md`     | Style Dictionary   | ✅ Complete |
| `plain-css.md`            | Plain `.css`       | ✅ Complete |
| `vanilla-extract.md`      | vanilla-extract    | ✅ Complete |
| `panda.md`                | Panda CSS          | ✅ Complete |
| `stitches.md`             | Stitches           | ✅ Complete |

Each file follows a fixed shape:

1. **When to use** — config key.
2. **Token emission** — example output, file layout, theming.
3. **Component class attachment** — how the component-builder references tokens.
4. **Custom token registration** — required when the system silently strips unregistered classes.
5. **Gotchas** — silent-fail traps.

## Picking a strategy when migrating

When the wizard offers to migrate from plain CSS to a framework, it suggests a CSS system based on the project's framework:

| Framework | First-choice CSS system | Why                                                         |
| --------- | ----------------------- | ----------------------------------------------------------- |
| React     | tailwind-v4             | Smallest learning curve, great IDE support, popular stack   |
| Vue       | unocss or tailwind-v4   | UnoCSS is faster + lighter; Tailwind v4 has bigger ecosystem |
| Angular   | tailwind-v3 or sass     | Angular tooling integrates better with both                 |
| Svelte    | tailwind-v4             | First-class svelte plugin                                   |
| Solid     | tailwind-v4             | Works without changes                                       |
| Lit       | css-vars                | Shadow DOM compatibility — utility CSS can't cross boundaries |
| Alpine    | tailwind-v4 or unocss   | Both pair cleanly with HTML-first patterns                  |
