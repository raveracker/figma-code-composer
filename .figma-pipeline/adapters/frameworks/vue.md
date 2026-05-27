# Vue adapter

## When to use
`config.framework.name == "vue"`. Sub-variants: `nuxt`, `vite`, `astro`.

## File template (component)

```vue
<!-- {{componentDir}}/{{Name}}/{{Name}}.vue -->
<script setup lang="ts">
import { computed } from "vue";

interface {{Name}}Props {
  {{propsList}}
}

const props = withDefaults(defineProps<{{Name}}Props>(), {{defaultProps}});
const emit = defineEmits<{{emitsType}}>();

const classes = computed(() => [
  "{{baseClasses}}",
  {{variantClassExpressions}}
]);
</script>

<template>
  <div :class="classes" v-bind="$attrs">
    {{renderBody}}
  </div>
</template>
```

## Props convention
- `defineProps<...>()` for type-safe props with explicit interface above.
- `defineEmits<...>()` for callbacks (instead of React's `on*` props).
- Slots replace React children: name your default slot `<slot />`, named slots `<slot name="trailing" />`.
- `v-model` for two-way binding when Figma indicates a controlled input.

## State idiom
- `ref` for primitives, `reactive` for objects, `computed` for derived.
- Never mirror props into a local ref — derive via `computed(() => props.x)`.
- Use `watchEffect` only for genuine side effects (DOM, network); never for data sync.

## Style attachment
- `:class` array with `computed` expressions for variant classes.
- `<style scoped>` blocks ONLY when `cssSystem.name == "css-vars"` and the styling cannot be expressed via utility classes.
- `cssSystem.name == "css-modules"`: import `<style module>` and reference `$style.root`.

## Story idiom
```ts
// {{Name}}.stories.ts
import type { Meta, StoryObj } from "@storybook/vue3";
import {{Name}} from "./{{Name}}.vue";

const meta = {
  title: "{{storyTitle}}",
  component: {{Name}},
  tags: ["autodocs"],
  parameters: {
    design: { type: "figma", url: "{{figmaDesignUrl}}" },
    a11y: { test: "error" }
  },
  argTypes: {{argTypesObject}},
  args: {{argsObject}},
  render: (args) => ({
    components: { {{Name}} },
    setup() { return { args }; },
    template: '<{{Name}} v-bind="args" />'
  })
} satisfies Meta<typeof {{Name}}>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {};
```

## Test idiom
```ts
// {{Name}}.spec.ts
import { describe, it, expect } from "vitest";
import { render, screen } from "@testing-library/vue";
import userEvent from "@testing-library/user-event";
import {{Name}} from "./{{Name}}.vue";

describe("{{Name}}", () => {
  it("renders", () => {
    render({{Name}});
    expect(screen.getByRole("{{role}}")).toBeInTheDocument();
  });
});
```

## Gotchas
- **`scoped` styles + utility CSS**: avoid `<style scoped>` when using Tailwind/UnoCSS — selectors get hashed and lose utility precedence.
- **`v-html`**: never emit unless the component genuinely needs it; XSS surface.
- **`defineProps` defaults**: `withDefaults(defineProps<...>(), {...})` is the only correct shape — object literal alone loses types.
- **Reactivity loss**: destructuring `props` breaks reactivity. Always `props.x` in `<script setup>` body.
