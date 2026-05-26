# Lit adapter

## When to use
`config.framework.name == "lit"`. Targets Lit 3.

## File template (component)

```ts
// {{componentDir}}/{{kebabName}}/{{kebabName}}.ts
import { LitElement, html, css } from "lit";
import { customElement, property } from "lit/decorators.js";
import { classMap } from "lit/directives/class-map.js";

@customElement("{{tagPrefix}}-{{kebabName}}")
export class {{Name}} extends LitElement {
  static styles = css`{{componentStyles}}`;

  {{propertyDeclarations}}    // @property() size: "sm" | "md" | "lg" = "md";

  override render() {
    const classes = { {{variantClassExpressions}} };
    return html`
      <div class=${classMap(classes)}>
        {{renderBody}}
      </div>
    `;
  }
}

declare global {
  interface HTMLElementTagNameMap {
    "{{tagPrefix}}-{{kebabName}}": {{Name}};
  }
}
```

## Props convention
- `@property()` for reactive properties.
- `@state()` for internal state.
- Tag name = `{config.framework.config.tagPrefix or 'app'}-{kebab-name}`. Single-word names get the prefix to satisfy Custom Elements naming.
- Events: dispatch `CustomEvent`s; consumer attaches via `@event-name=`.

## State idiom
- `@state()` for internal reactive state.
- Lit auto-re-renders on property/state change; no manual signal/effect machinery.
- Lifecycle: `connectedCallback`, `disconnectedCallback`, `firstUpdated`, `updated`.

## Style attachment
- `static styles = css\`…\`` (constructable stylesheets) — Lit's primary path.
- Shadow DOM by default: tokens defined as CSS custom properties on `:host` and inherited downward.
- Utility CSS (Tailwind/UnoCSS): NOT idiomatic in Lit's Shadow DOM (utility classes don't penetrate shadow boundaries). Use `static styles` with CSS-var-driven design tokens.
- Light DOM mode (no shadow): override `createRenderRoot() { return this; }` — then utility classes work, but lose encapsulation.

## Story idiom
```ts
// {{kebabName}}.stories.ts
import type { Meta, StoryObj } from "@storybook/web-components";
import { html } from "lit";
import "./{{kebabName}}";

const meta = {
  title: "{{storyTitle}}",
  component: "{{tagPrefix}}-{{kebabName}}",
  tags: ["autodocs"],
  parameters: { design: { type: "figma", url: "{{figmaDesignUrl}}" }, a11y: { test: "error" } },
  argTypes: {{argTypesObject}},
  args: {{argsObject}},
  render: (args) => html`<{{tagPrefix}}-{{kebabName}} {{litTemplateArgs}}></{{tagPrefix}}-{{kebabName}}>`
} satisfies Meta;
export default meta;
type Story = StoryObj<typeof meta>;
export const Default: Story = {};
```

## Test idiom
```ts
// {{kebabName}}.test.ts
import { describe, it, expect } from "vitest";
import { fixture, html } from "@open-wc/testing";
import "./{{kebabName}}";
import type { {{Name}} } from "./{{kebabName}}";

describe("{{Name}}", () => {
  it("renders", async () => {
    const el: {{Name}} = await fixture(html`<{{tagPrefix}}-{{kebabName}}></{{tagPrefix}}-{{kebabName}}>`);
    expect(el).to.exist;
    expect(el.shadowRoot?.querySelector("{{rootSelector}}")).to.exist;
  });
});
```

## Gotchas
- **Shadow DOM + utility CSS**: utility classes from Tailwind/UnoCSS do NOT cross shadow boundaries. Either disable shadow (`createRenderRoot`) or convert utilities to CSS-var-driven `static styles`.
- **Tag naming**: single-word names need a prefix per the spec (`button` → `app-button`).
- **`@property()` reflection**: set `reflect: true` only when you genuinely need the attribute to mirror the property — perf hit.
