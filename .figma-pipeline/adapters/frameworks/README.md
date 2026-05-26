# Framework adapters

Each adapter is a single markdown file telling `component-builder`, `icon-generator`, `story-author`, and `test-author` exactly how to emit code for one framework. The component-builder reads `adapters/frameworks/<framework.name>.md` after loading the manifest slice; absent file → fall back to React idioms with a flag.

| File                  | Framework      | Status     |
| --------------------- | -------------- | ---------- |
| `react.md`            | React          | ✅ Complete |
| `vue.md`              | Vue 3          | ✅ Complete |
| `angular.md`          | Angular ≥17    | ✅ Complete |
| `svelte.md`           | Svelte 5       | ✅ Complete |
| `solid.md`            | Solid          | ✅ Complete |
| `lit.md`              | Lit 3          | ✅ Complete |
| `alpine.md`           | Alpine.js      | ✅ Complete |

Each adapter file follows a fixed shape:

1. **When to use** — config keys that select this adapter.
2. **File template** — minimum component file body, with `{{placeholder}}` slots the builder fills.
3. **Props convention** — how Figma `variants` + `states` map to framework props.
4. **State idiom** — local state, derived values, side effects.
5. **Style attachment** — how classes/styles attach per CSS system.
6. **Story idiom** — Storybook/Histoire/Ladle render shape.
7. **Test idiom** — testing-library render shape.
8. **Gotchas** — silent-fail traps specific to this framework.
