# Solid adapter

## When to use
`config.framework.name == "solid"`.

## File template (component)

```tsx
// {{componentDir}}/{{Name}}/{{Name}}.tsx
import { type Component, type JSX, splitProps, createMemo } from "solid-js";
{{#if useCva}}import { cva, type VariantProps } from "class-variance-authority";{{/if}}

{{#if useCva}}
const {{nameCamel}}Variants = cva("{{baseClasses}}", { variants: {{variantsObject}}, defaultVariants: {{defaultVariants}} });
{{/if}}

export interface {{Name}}Props extends JSX.HTMLAttributes<HTMLDivElement>{{#if useCva}}, VariantProps<typeof {{nameCamel}}Variants>{{/if}} {
  {{propsList}}
}

export const {{Name}}: Component<{{Name}}Props> = (props) => {
  const [local, rest] = splitProps(props, [{{splitKeys}}]);
  const classes = createMemo(() => {{nameCamel}}Variants({ {{variantProps}} }) + " " + (local.class ?? ""));
  return (
    <div class={classes()} {...rest}>
      {{renderBody}}
    </div>
  );
};
```

## Props convention
- `Component<Props>` from `solid-js`.
- `splitProps` to separate Solid-managed props from passthrough.
- IMPORTANT: native HTML attr is `class` (not `className`) in Solid.
- Solid props are reactive — destructure via `splitProps`, never via `const { x } = props` (loses reactivity).

## State idiom
- `createSignal` for reactive state. `createMemo` for derived. `createEffect` for side effects only.
- Never mirror props into a signal — derive via `createMemo(() => props.x)`.

## Style attachment
Same as React, but use `class` attribute (not `className`):

| `cssSystem.name`       | Attachment                                                |
| ---------------------- | --------------------------------------------------------- |
| `tailwind-v4`/`v3`     | `class="..."`                                             |
| `unocss`               | `class="..."`                                             |
| `css-modules`          | `import styles from "./{{Name}}.module.css"; class={styles.root}` |

## Story idiom
```tsx
// {{Name}}.stories.tsx
import type { Meta, StoryObj } from "storybook-solidjs";
import { {{Name}} } from "./{{Name}}";

const meta = {
  title: "{{storyTitle}}",
  component: {{Name}},
  tags: ["autodocs"],
  parameters: { design: { type: "figma", url: "{{figmaDesignUrl}}" }, a11y: { test: "error" } },
  args: {{argsObject}}
} satisfies Meta<typeof {{Name}}>;
export default meta;
type Story = StoryObj<typeof meta>;
export const Default: Story = {};
```

## Test idiom
```tsx
// {{Name}}.test.tsx
import { describe, it, expect } from "vitest";
import { render, screen } from "@solidjs/testing-library";
import { {{Name}} } from "./{{Name}}";

describe("{{Name}}", () => {
  it("renders", () => {
    render(() => <{{Name}} />);
    expect(screen.getByRole("{{role}}")).toBeInTheDocument();
  });
});
```

## Gotchas
- **`className` ≠ `class`**: Solid uses the native `class` attribute. Component-builder MUST emit `class`, not `className`.
- **Prop destructuring kills reactivity**: always `props.x`, never `const { x } = props`.
- **`<For>` / `<Show>`**: use Solid's control-flow components instead of `.map(...)` / `&&` patterns for reactive lists.
