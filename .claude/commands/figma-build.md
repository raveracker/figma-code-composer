---
description: Build NEW components/icons/tokens from a Figma design via the full figma-coordinator pipeline (fetch → tokens → icons + components in parallel → stories + tests in parallel).
argument-hint: "<figma-url> [layerHint]"
---

# /figma-build — full pipeline (create intent)

Spawn `figma-coordinator` (model: sonnet) with:

```jsonc
{
  "url": "$1",
  "intent": "create",
  "scope": "full",
  "layerHint": "$2"   // optional
}
```

Pre-flight: requires `.figma-pipeline/config.json` (run `/init` first if missing).

Do not write any file directly. Do not commit. Do not push.
