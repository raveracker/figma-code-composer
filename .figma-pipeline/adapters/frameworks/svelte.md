# Svelte adapter

## When to use
`config.framework.name == "svelte"`. Targets Svelte 5 (runes mode). For Svelte 4, replace `$state`/`$derived` with `let` + `$:` reactive statements.

## File template (component)

```svelte
<!-- {{componentDir}}/{{Name}}/{{Name}}.svelte -->
<script lang="ts">
  interface Props {
    {{propsList}}
  }
  let { {{destructuredProps}}, ...rest }: Props = $props();

  const classes = $derived(`{{baseClasses}} {{variantTernaries}}`);
</script>

<div class={classes} {...rest}>
  {{renderBody}}
</div>
```

## Props convention
- `$props()` for component props (Svelte 5 runes).
- Callbacks as props (`onClick`, `onChange`) — no `createEventDispatcher`.
- Slots: `let { children } = $props(); … {@render children?.()}`.
- `bind:` directive for two-way binding when Figma indicates a controlled input.

## State idiom
- `$state(initial)` for reactive state; `$derived(expr)` for computed.
- `$effect(() => { … })` only for true side effects.
- Never mirror props into `$state` — `$derived` from props.

## Style attachment
- Utility CSS (Tailwind, UnoCSS): `class={classes}` with computed value.
- Scoped: `<style>` block at end of file (Svelte auto-scopes selectors).
- `cssSystem.name == "css-modules"`: not idiomatic in Svelte — fall back to scoped `<style>`.

## Story idiom
```ts
// {{Name}}.stories.ts
import type { Meta, StoryObj } from "@storybook/svelte";
import {{Name}} from "./{{Name}}.svelte";

const meta = {
  title: "{{storyTitle}}",
  component: {{Name}},
  tags: ["autodocs"],
  parameters: {
    design: { type: "figma", url: "{{figmaDesignUrl}}" },
    a11y: { test: "error" }
  },
  argTypes: {{argTypesObject}},
  args: {{argsObject}}
} satisfies Meta<{{Name}}>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Default: Story = {};
```

## Test idiom
```ts
// {{Name}}.test.ts
import { describe, it, expect } from "vitest";
import { render, screen } from "@testing-library/svelte";
import {{Name}} from "./{{Name}}.svelte";

describe("{{Name}}", () => {
  it("renders", () => {
    render({{Name}});
    expect(screen.getByRole("{{role}}")).toBeInTheDocument();
  });
});
```

## Gotchas
- **Svelte 4 vs 5**: detect `framework.version`. Adapter defaults to 5 (runes). For 4, emit `export let prop` instead of `$props()`.
- **Scoped styles + global utilities**: scoped styles hash selectors. Use `:global(.foo)` or skip the `<style>` block when using Tailwind/UnoCSS.
- **`bind:value` on custom components**: requires `let { value = $bindable() } = $props();` in Svelte 5.
