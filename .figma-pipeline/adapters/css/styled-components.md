# styled-components adapter

## When to use
`config.cssSystem.name == "styled-components"`. Runtime CSS-in-JS for React. Tested against `styled-components@6+`.

## Token emission

Strategy: `js-tokens`. Emit a typed theme object consumed via `<ThemeProvider>`:

```ts
// {{tokens.outputDir}}/theme.ts
export const lightTheme = {
  colors: {
    brand: {
      primary: "#FF6E1D",
      secondary: "#1A1A1A"
    },
    surface: {
      bg: "#FFFFFF",
      fg: "#0A0A0A"
    }
  },
  space: { 1: "0.25rem", 2: "0.5rem", 3: "0.75rem", 4: "1rem" },
  radii: { sm: "0.25rem", md: "0.5rem", lg: "1rem" },
  fontSizes: { sm: "0.875rem", md: "1rem", lg: "1.125rem" }
} as const;

export const darkTheme: typeof lightTheme = {
  ...lightTheme,
  colors: {
    ...lightTheme.colors,
    surface: { bg: "#0A0A0A", fg: "#FFFFFF" },
    brand: { ...lightTheme.colors.brand, primary: "#FF8A4A" }
  }
} as const;

export type AppTheme = typeof lightTheme;
```

Token-builder also emits a `DefaultTheme` declaration to enable typed `theme` access in styled components:

```ts
// {{tokens.outputDir}}/styled.d.ts
import "styled-components";
import type { AppTheme } from "./theme";
declare module "styled-components" {
  export interface DefaultTheme extends AppTheme {}
}
```

## App-shell setup

Wrap the consumer's app entry in `<ThemeProvider>`:

```tsx
import { ThemeProvider } from "styled-components";
import { lightTheme, darkTheme } from "./design-tokens/theme";

export function AppProviders({ children, mode = "light" }: { children: React.ReactNode; mode?: "light" | "dark" }) {
  return <ThemeProvider theme={mode === "dark" ? darkTheme : lightTheme}>{children}</ThemeProvider>;
}
```

## Component class attachment

```tsx
// {{Name}}.tsx
import styled from "styled-components";

const Root = styled.div<{ $size: "sm" | "md" | "lg"; $disabled?: boolean }>`
  background: ${({ theme }) => theme.colors.brand.primary};
  padding: ${({ theme, $size }) => theme.space[$size === "sm" ? 1 : $size === "md" ? 2 : 3]};
  border-radius: ${({ theme }) => theme.radii.md};
  opacity: ${({ $disabled }) => ($disabled ? 0.5 : 1)};

  &:hover {
    background: ${({ theme }) => theme.colors.brand.secondary};
  }
`;

export interface {{Name}}Props {
  size?: "sm" | "md" | "lg";
  disabled?: boolean;
  children?: React.ReactNode;
}

export function {{Name}}({ size = "md", disabled, children }: {{Name}}Props) {
  return <Root $size={size} $disabled={disabled}>{children}</Root>;
}
```

**Rules**:
- Use `$`-prefixed transient props (`$size`, `$disabled`) to avoid forwarding non-DOM props to the underlying element.
- Read tokens from `theme` — never inline hex/rem.
- Co-locate the `styled(...)` declaration above the component (one file per component, per the framework adapter).

## Custom token registration

Not applicable — styled-components reads the theme object directly; no merger to register.

## SSR setup (Next.js App Router)

Styled-components requires a registry component for SSR streaming. Token-builder also emits this when `framework.variant == "next"`:

```tsx
// {{tokens.outputDir}}/StyledComponentsRegistry.tsx
"use client";
import { useState } from "react";
import { useServerInsertedHTML } from "next/navigation";
import { ServerStyleSheet, StyleSheetManager } from "styled-components";

export function StyledComponentsRegistry({ children }: { children: React.ReactNode }) {
  const [sheet] = useState(() => new ServerStyleSheet());
  useServerInsertedHTML(() => {
    const styles = sheet.getStyleElement();
    sheet.instance.clearTag();
    return <>{styles}</>;
  });
  if (typeof window !== "undefined") return <>{children}</>;
  return <StyleSheetManager sheet={sheet.instance}>{children}</StyleSheetManager>;
}
```

Wrap `app/layout.tsx`'s `<body>` content with `<StyledComponentsRegistry>`.

## Gotchas

- **Runtime cost.** styled-components evaluates at render time. For large component trees, prefer zero-runtime (`vanilla-extract`, `panda`) when build complexity is acceptable.
- **`"use client"` required** in Next.js App Router — every file that imports `styled-components` is a client component. Token-builder emits the directive automatically.
- **Server Components incompatible.** Styled-components is client-only; cannot be used inside RSC.
- **Babel plugin recommended.** `babel-plugin-styled-components` enables better displayNames + SSR identification. Token-builder flags missing plugin in `next.config.js` / `.babelrc` as a warning, never auto-installs.
- **Transient props (`$prop`)**: always use the `$` prefix for non-DOM props passed to styled elements. Without it, React warns about unknown DOM attributes.
- **Theme typing**: the `styled.d.ts` declaration must be picked up by `tsconfig.json` `include`. Token-builder flags missing inclusion.
- **Dynamic class names**: works at runtime, no JIT-style purge — bundle size scales with styled declarations, not template strings.
