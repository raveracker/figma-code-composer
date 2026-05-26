# Component layout — per framework & methodology

> Read by `component-builder`, `story-author`, and `test-author` to resolve where files go and what they look like. The figma-fetcher reads this to assign `layer` and `targetDir` in the manifest.

## Layer resolution (manifest → disk)

The fetcher classifies each Figma component into a `layer` based on `config.components.designMethodology`:

### `designMethodology: atomic`

| `layer`     | Heuristic                                                              | `targetDir` (default)                |
| ----------- | ---------------------------------------------------------------------- | ------------------------------------ |
| `atom`      | No composed components; primitive only (button, input, badge, icon)    | `config.components.atomicLayout.atomsDir`     |
| `molecule`  | Composes ≥1 atom; single concern (search-bar, card, pill-tabs)         | `config.components.atomicLayout.moleculesDir` |
| `organism`  | Composes molecules + atoms; multi-concern (header, product-card grid)  | `config.components.atomicLayout.organismsDir` |
| `template`  | Page-level layout w/o data; placeholder slots                          | `config.components.atomicLayout.templatesDir` |
| `page`      | Concrete page                                                          | `config.components.atomicLayout.templatesDir` (filed under `pages/` subdir) |

### `designMethodology: feature-sliced`

| `layer`    | `targetDir`                                |
| ---------- | ------------------------------------------ |
| `shared`   | `config.components.featureSlicedLayout.sharedDir`   |
| `entity`   | `config.components.featureSlicedLayout.entitiesDir` |
| `feature`  | `config.components.featureSlicedLayout.featuresDir` |
| `widget`   | `config.components.featureSlicedLayout.widgetsDir`  |
| `page`     | `config.components.featureSlicedLayout.pagesDir`    |

### `designMethodology: flat` / `custom`

All components → `config.components.flatLayout.componentsDir`. `layer` is recorded for tagging but does not influence placement.

### Override

Any Figma frame can override placement by adding a `figma-layer` description annotation: `layer:organism` overrides the heuristic. Recorded verbatim in the manifest and surfaced to the user as a flag (never silently honoured).

---

## File layout (per framework)

The component file extension + sibling file conventions vary by framework. The `component-builder` writes a folder per component containing the main file + barrel + story + test (when enabled). `fileNaming` controls the inner naming.

### React (`framework.name: react`)

```
<targetDir>/<Name>/
  ├─ <Name>.tsx           # main component (default export named <Name>)
  ├─ <Name>.module.css    # only if cssSystem.name == "css-modules"
  ├─ <Name>.stories.tsx   # if stories.enabled
  ├─ <Name>.test.tsx      # if tests.enabled
  └─ index.ts             # re-exports
```

Variants: with `fileNaming: index`, the main file becomes `index.tsx` and there is no barrel. With `fileNaming: match-folder`, folder + file are lowercase.

### Vue (`framework.name: vue`)

```
<targetDir>/<Name>/
  ├─ <Name>.vue            # SFC with <script setup lang="ts">
  ├─ <Name>.stories.ts     # CSF3
  ├─ <Name>.spec.ts        # vitest + vue-testing-library
  └─ index.ts
```

### Angular (`framework.name: angular`)

```
<targetDir>/<kebab-name>/
  ├─ <kebab-name>.component.ts     # standalone component
  ├─ <kebab-name>.component.html
  ├─ <kebab-name>.component.scss   # or .css depending on cssSystem
  ├─ <kebab-name>.component.spec.ts
  ├─ <kebab-name>.stories.ts
  └─ index.ts
```

Angular uses kebab-case folder + selector convention; selector = `<prefix>-<kebab-name>` (prefix configured via `framework.config.selectorPrefix`, default `app-`).

### Svelte (`framework.name: svelte`)

```
<targetDir>/<Name>/
  ├─ <Name>.svelte
  ├─ <Name>.stories.ts
  ├─ <Name>.test.ts
  └─ index.ts
```

### Solid (`framework.name: solid`)

Identical layout to React but Solid components use `Component<Props>` from `solid-js`.

### Lit (`framework.name: lit`)

```
<targetDir>/<kebab-name>/
  ├─ <kebab-name>.ts       # @customElement('<prefix>-<kebab-name>')
  ├─ <kebab-name>.styles.ts
  ├─ <kebab-name>.stories.ts
  ├─ <kebab-name>.test.ts
  └─ index.ts
```

Tag name = `<prefix>-<kebab-name>` (prefix from `framework.config.tagPrefix`, default `app-`). Names with a single word get a dash appended (`button` → `app-button`).

### Alpine (`framework.name: alpine`)

```
<targetDir>/<kebab-name>/
  ├─ <kebab-name>.html         # markup + x-data
  ├─ <kebab-name>.alpine.ts    # behavior (registered with Alpine.data)
  ├─ <kebab-name>.stories.ts   # via storybook-html
  └─ index.ts                  # re-export of data fn
```

---

## Naming

`components.namingConvention` controls the `<Name>` token above:

| Setting       | Example                |
| ------------- | ---------------------- |
| `PascalCase`  | `ProductCtaBar`        |
| `kebab-case`  | `product-cta-bar`      |
| `camelCase`   | `productCtaBar`        |

Angular and Lit always use kebab-case for files + selectors regardless of this setting (framework convention wins). React/Vue/Svelte/Solid default to PascalCase.

---

## Barrel files

`index.ts` (or `index.js`) re-exports the named component + types:

```ts
// React/Solid
export { ProductCtaBar } from "./ProductCtaBar";
export type { ProductCtaBarProps } from "./ProductCtaBar";

// Vue
export { default as ProductCtaBar } from "./ProductCtaBar.vue";

// Lit
export { ProductCtaBar } from "./product-cta-bar";
```

When `fileNaming: index`, the inner file IS the barrel and no separate `index.ts` is emitted.

---

## Story title convention

`stories.titleConvention` is a template with placeholders:

- `{Layer}` — `Atoms`, `Molecules`, `Organisms`, `Templates` (atomic); `Shared`, `Entities`, `Features`, `Widgets`, `Pages` (feature-sliced); `Components` (flat).
- `{Name}` — component name in PascalCase.
- `{Domain}` — subdirectory name (only resolves for nested layouts like `organisms/user/ProfileHeader` → `User`).

Default: `Components/{Layer}/{Name}` → `Components/Molecules/ProductCtaBar`.

---

## Update flow (`intent: "update"`)

When `existsOnDisk: true`:

1. `component-builder` MUST patch the file at `diskPath` — never blind-overwrite.
2. New props/states are added; removed props are kept with `@deprecated` JSDoc and a `// removed in <runId>` marker.
3. Story/test files are re-synced (Rule: stories rewritten on major prop-surface change; tests added-only never deleted).
4. Renames require `previousName` in the run-summary; coordinator escalates a missing previousName.
