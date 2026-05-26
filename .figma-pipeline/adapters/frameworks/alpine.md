# Alpine.js adapter

## When to use
`config.framework.name == "alpine"`. Alpine.js 3+.

## File template (markup + behavior)

```html
<!-- {{componentDir}}/{{kebabName}}/{{kebabName}}.html -->
<template x-data="{{nameCamel}}" {{declarativeProps}}>
  <div class="{{baseClasses}}" :class="classes">
    {{renderBody}}
  </div>
</template>
```

```ts
// {{componentDir}}/{{kebabName}}/{{kebabName}}.alpine.ts
import type { AlpineComponent } from "alpinejs";

interface {{Name}}Props {
  {{propsList}}
}

export const {{nameCamel}}: AlpineComponent<{{Name}}Props> = ({
  {{defaultProps}},
  get classes() {
    return [
      "{{baseClasses}}",
      {{variantClassExpressions}}
    ].join(" ");
  },
  init() {
    {{initBody}}
  }
});
```

```ts
// {{componentDir}}/{{kebabName}}/index.ts
import Alpine from "alpinejs";
import { {{nameCamel}} } from "./{{kebabName}}.alpine";
Alpine.data("{{nameCamel}}", () => ({{nameCamel}}));
export { {{nameCamel}} };
```

## Props convention
- Declarative props as `x-data` attributes (`size="md"`, `disabled`).
- Inside the component, props are properties on the `x-data` object.
- No native two-way binding — use `x-model` on form inputs, custom getter/setter elsewhere.

## State idiom
- Properties on the `x-data` object are reactive.
- Getters (`get xyz() { ... }`) work as computed.
- Methods on the object handle events (`@click="handle"`).

## Style attachment
- `class="..."` with static base classes.
- `:class="..."` for dynamic variant classes — string or object form.
- Tailwind/UnoCSS native fit.

## Story idiom
```ts
// {{kebabName}}.stories.ts
import type { Meta, StoryObj } from "@storybook/html";

const meta = {
  title: "{{storyTitle}}",
  tags: ["autodocs"],
  parameters: { design: { type: "figma", url: "{{figmaDesignUrl}}" }, a11y: { test: "error" } },
  argTypes: {{argTypesObject}},
  args: {{argsObject}},
  render: (args) => `
    <div x-data="{{nameCamel}}" ${Object.entries(args).map(([k,v]) => `${k}="${v}"`).join(" ")}>
      <!-- ... template body ... -->
    </div>
  `
} satisfies Meta;
export default meta;
type Story = StoryObj<typeof meta>;
export const Default: Story = {};
```

## Test idiom
Alpine has no canonical testing-library. Smoke-test the registered data factory directly:

```ts
// {{kebabName}}.test.ts
import { describe, it, expect } from "vitest";
import { {{nameCamel}} } from "./{{kebabName}}.alpine";

describe("{{Name}}", () => {
  it("default state is sane", () => {
    const inst = {{nameCamel}}();
    expect(inst.classes).toContain("{{baseClass}}");
  });
});
```

For end-to-end interaction tests, Playwright is the right tool (`config.tests.framework == "playwright"`).

## Gotchas
- **Alpine.start()**: must run after `Alpine.data(...)` registrations. Component-builder should ensure the page-level Alpine init imports the component before `Alpine.start()`.
- **`x-init` vs `init()`**: `init()` inside `x-data` runs once after the component mounts; `x-init` is for inline DOM-level init.
- **Reactivity through closures**: capturing a property in a function still goes through Alpine's reactive proxy; arrow functions are fine.
- **No SSR**: Alpine is purely client-side. Don't add this scaffold to an SSR-only stack.
