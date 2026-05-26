# Cursor figma-coordinator prompt

When Cursor needs to act as the coordinator, follow `.claude/agents/figma-coordinator.md` verbatim — the protocol, write scope, error handling, and report format apply identically.

Cursor deltas:

- No `Agent` tool. Run each specialist agent inline in a single conversation thread, including its agent file as the system prompt for the segment.
- Use Cursor's MCP server entries (configured via Cursor settings) for `figma:*` tool calls.

The pipeline is invoked via the slash commands mirrored in `.cursor/prompts/commands/`.
