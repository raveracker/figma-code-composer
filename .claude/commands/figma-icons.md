---
description: Generate or repair ONLY icons from a Figma design via the figma-coordinator pipeline (figma-fetcher → icon-generator). No components, tokens, stories, or tests.
argument-hint: "<figma-url>"
---

# /figma-icons — icons-only

Spawn `figma-coordinator` (model: sonnet) with:

```jsonc
{
  "url": "$1",
  "intent": "create",   // or "update" if existing icons matched
  "scope": "icons-only"
}
```

Pre-flight: requires `.figma-pipeline/config.json`. Aborts if the selection contains no icon-shaped nodes.

Do not write any file directly. Do not commit. Do not push.
