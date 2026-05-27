# Cursor figma-coordinator prompt

When Cursor needs to act as the coordinator, follow `.claude/agents/figma-coordinator.md` verbatim — the protocol, write scope, error handling, and report format apply identically.

Cursor deltas:

- No `Agent` tool. Run each specialist agent inline in a single conversation thread, including its agent file as the system prompt for the segment.
- Use Cursor's MCP server entries (configured via Cursor settings) for `figma:*` tool calls.

## Complexity routing — Cursor specifics

The coordinator's routing table resolves each tier to an abstract size (`sm` / `md` / `lg`). **Cursor agents inherit the user's currently-selected model from the Cursor settings UI; there is no per-call model override.**

What this means in practice:

| Tier      | Abstract size | What changes in Cursor                                       |
| --------- | ------------- | ------------------------------------------------------------ |
| trivial   | `sm`          | Skill set narrowed; model unchanged                          |
| moderate  | `md`          | Skill set partial; model unchanged                           |
| complex   | `lg`          | Full skill set; model unchanged                              |
| extreme   | `lg`          | Full skill set + final `code-reviewer` pass; model unchanged |

**The skill-set, second-pass-review, KG-query, KG-merge, and handover behaviors all apply identically to Cursor** — only the model column is a no-op.

The coordinator MUST surface the recommended size as a chat prefix so the user can switch model if they want:

```
[fcc routing] tier=complex, recommended size=lg (e.g. Claude Opus 4.7 / GPT-5 / o3).
Current Cursor model will be used — switch in Settings → Models if you want a different size.
```

This prefix appears before any specialist is invoked. Do not block on the user's response — proceed with the current model.

## KG / handover CLI calls

These work identically under Cursor because they're plain shell — `npx fcc kg:query`, `npx fcc kg:stage`, `npx fcc kg:merge`, `npx fcc handover` all run via Cursor's terminal-execution capability. Same exit codes apply.

The pipeline is invoked via the slash commands mirrored in `.cursor/prompts/commands/`.
