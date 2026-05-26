# Design-system adapters

A **design system** (DS) is a higher-level layer on top of `framework` + `cssSystem`: it ships its own components, tokens, theming model, and idioms. When the wizard sets `config.designSystem.name`, `component-builder` and `story-author` shift to emitting DS-native components instead of plain HTML primitives + utility classes.

When `designSystem.name == "none"` (the default), the framework + CSS-system adapters drive everything.

| File                | Design system               | Status     |
| ------------------- | --------------------------- | ---------- |
| `braid.md`          | Braid (SEEK)                | ✅ Complete |
| `chakra.md`         | Chakra UI                   | ⏳ Stub     |
| `mantine.md`        | Mantine                     | ⏳ Stub     |
| `mui.md`            | Material UI                 | ⏳ Stub     |
| `radix.md`          | Radix UI (primitives)       | ⏳ Stub     |
| `shadcn.md`         | shadcn/ui                   | ⏳ Stub     |
| `headlessui.md`     | Headless UI                 | ⏳ Stub     |

## Per-adapter shape

1. **When to use** — `designSystem.name` value + framework constraint.
2. **Dependencies** — npm packages the consumer must install.
3. **Theming model** — how the DS handles themes; how the wizard sets it.
4. **Token mapping** — Figma variable → DS token (or a fallback strategy).
5. **Component mapping** — how `component-builder` renders primitives.
6. **Story idiom** — DS-specific story setup (BraidProvider, ChakraProvider, etc.).
7. **Test idiom** — DS-specific test setup.
8. **Gotchas**.

## Interaction with other adapters

| Adapter family                    | Source of truth when `designSystem.name != "none"`                        |
| --------------------------------- | -------------------------------------------------------------------------- |
| `adapters/frameworks/<name>.md`   | Still governs file extensions, props convention, state idiom               |
| `adapters/css/<name>.md`          | Token-builder still emits in the configured strategy; component-builder ignores `cssSystem` styling and uses DS components instead |
| `adapters/design-systems/<name>.md` | Governs what JSX/markup component-builder emits AND how stories wire providers |
