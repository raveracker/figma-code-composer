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

Pre-flight: requires `.figma-pipeline/config.json` (run `/init-figma-compose` first if missing).
 The wizard verifies Figma MCP is reachable as a hard gate — if config.json exists, MCP was alive at wizard time. If MCP has since dropped, `figma-coordinator` will surface that to the user before any specialist runs.

Do not write any file directly. Do not commit. Do not push.
