---
description: Generate or refresh ONLY design tokens from a Figma design via the figma-coordinator pipeline (figma-fetcher → token-builder). No components or icons.
argument-hint: "<figma-url>"
---

# /figma-tokens — tokens-only

Spawn `figma-coordinator` (model: sonnet) with:

```jsonc
{
  "url": "$1",
  "intent": "create",   // or "update" if existing tokens matched
  "scope": "tokens-only"
}
```

Pre-flight: requires `.figma-pipeline/config.json`. Token output goes to `config.tokens.outputDir` in the format defined by `config.tokens.strategy` (see `protocols/token-strategy.md`).

Do not write any file directly. Do not commit. Do not push.
