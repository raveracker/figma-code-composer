# Codex code-reviewer

Mirror of `.claude/agents/code-reviewer.md`. No tooling deltas — pure file IO + bash. Codex has no sub-agent spawner: when the coordinator's session reaches the extreme-tier review step, it reads this file as guidance and performs the review inline (rather than spawning a separate `codex run-agent code-reviewer`).

See `.claude/agents/code-reviewer.md` for the full role definition, review checklist, and output format.
