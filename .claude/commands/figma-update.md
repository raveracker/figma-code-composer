---
description: UPDATE existing components/icons/tokens from a changed Figma design via the figma-coordinator pipeline (patches in place, refreshes stories + tests).
argument-hint: "<figma-url> [layerHint]"
---

# /figma-update — full pipeline (update intent)

Spawn `figma-coordinator` (model: sonnet) with:

```jsonc
{
  "url": "$1",
  "intent": "update",
  "scope": "full",
  "layerHint": "$2"   // optional
}
```

Pre-flight: requires `.figma-pipeline/config.json`. Existing files at the resolved paths are patched, not overwritten — see `protocols/component-layout.md` § Update flow.

Do not write any file directly. Do not commit. Do not push.
