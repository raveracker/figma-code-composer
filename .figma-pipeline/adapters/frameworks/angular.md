# Angular adapter

## When to use
`config.framework.name == "angular"`. Tested against Angular ≥17 (standalone components + signals).

## File template (component)

```ts
// {{componentDir}}/{{kebabName}}/{{kebabName}}.component.ts
import { Component, ChangeDetectionStrategy, input, output, computed } from "@angular/core";
import { NgClass } from "@angular/common";

@Component({
  selector: "{{selectorPrefix}}-{{kebabName}}",
  standalone: true,
  imports: [NgClass],
  templateUrl: "./{{kebabName}}.component.html",
  styleUrls: {{styleUrlsArray}},
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class {{Name}}Component {
  {{inputsList}}     // size = input<"sm"|"md"|"lg">("md");
  {{outputsList}}    // valueChange = output<string>();

  readonly classes = computed(() => ({
    "{{baseClass}}": true,
    {{variantClassExpressions}}
  }));
}
```

```html
<!-- {{kebabName}}.component.html -->
<div [ngClass]="classes()">
  {{renderBody}}
</div>
```

## Props convention
- `input()` / `input.required()` (Angular 17.1+) for typed inputs.
- `output()` for event emitters (replaces `@Output() x = new EventEmitter`).
- Selector = `{config.framework.config.selectorPrefix or 'app'}-{kebab-name}`.
- File naming: kebab-case (`product-cta-bar.component.ts`).

## State idiom
- `signal()` for state; `computed()` for derived; `effect()` only for side effects.
- `ChangeDetectionStrategy.OnPush` — mandatory for design-system components.
- Never `@Input() set x(...)` patterns; use `input.transform` instead.

## Style attachment
- `styleUrls: ["./<name>.component.scss"]` when `cssSystem.name == "sass"`.
- `styleUrls: ["./<name>.component.css"]` for plain CSS.
- Tailwind/UnoCSS: classes go in the template, no styleUrls.
- `[ngClass]` for dynamic variant binding (object form preferred).

## Story idiom
```ts
// {{kebabName}}.stories.ts
import type { Meta, StoryObj } from "@storybook/angular";
import { {{Name}}Component } from "./{{kebabName}}.component";

const meta: Meta<{{Name}}Component> = {
  title: "{{storyTitle}}",
  component: {{Name}}Component,
  tags: ["autodocs"],
  parameters: {
    design: { type: "figma", url: "{{figmaDesignUrl}}" },
    a11y: { test: "error" }
  },
  argTypes: {{argTypesObject}},
  args: {{argsObject}}
};
export default meta;
type Story = StoryObj<{{Name}}Component>;

export const Default: Story = {};
```

## Test idiom
```ts
// {{kebabName}}.component.spec.ts
import { TestBed } from "@angular/core/testing";
import { {{Name}}Component } from "./{{kebabName}}.component";

describe("{{Name}}Component", () => {
  it("renders", async () => {
    const fixture = TestBed.createComponent({{Name}}Component);
    fixture.detectChanges();
    expect(fixture.nativeElement.querySelector("{{rootSelector}}")).toBeTruthy();
  });
});
```

If `tests.unit.testingLibrary == "@testing-library/angular"`, use `render` from `@testing-library/angular` instead of `TestBed`.

## Gotchas
- **Selector prefix**: must be set in `framework.config.selectorPrefix`; without it Angular CLI lints will fail.
- **OnPush + signals**: signals + OnPush is the high-perf default. Avoid mixing with `@Input` setters.
- **Module-based components** (pre-Angular-15): not supported. Adapter targets standalone components only.
- **`*ngIf` deprecation**: prefer `@if` control-flow (Angular 17+); fallback to `*ngIf` only if `framework.version` < 17.
