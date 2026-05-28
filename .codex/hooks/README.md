# Codex hooks — index

Codex has no native lifecycle hooks. `.codex/wrap.sh` simulates them by running these scripts around every `codex run <cmd>` invocation. Each hook maps to one or more CLAUDE.md binding rules.

## Lifecycle

```
./codex-run <cmd>   (= .codex/wrap.sh <cmd>)
   │
   ├─► pre-command.sh   ──┐
   │                      │  rule 1  (allowlist defaults — refuses without config when cmd ≠ init-figma-compose)
   │                      │  rule 1  (.env block — supporting / strict)
   │                      │  routing (figma URL nudge → rules 1+2)
   │                      └─►
   ▼
codex exec "<prompt>"     ◄── the actual work, ONE agentic session (rules 2-7 enforced inline by the agent)
   │
   ├─► post-command.sh  ──┐
   │                      │  rule 2  (manifest schema integrity)
   │                      │  rule 3  (figmaVariable not resolved to hex/rem/rgb)
   │                      │  rule 4  (unbound entries flagged + reported)
   │                      │  rule 5  (blocking ambiguities surfaced if the run proceeded)
   │                      │  rule 6  (injectionObservations printed verbatim)
   │                      │  rule 7  (config.json validates; token files brace-balanced / valid JSON)
   │                      └─►
   ▼
   on-exit.sh            ──── working-tree + last-run summary
```

## Files

| Hook                | Lifecycle point      | Rules covered          |
| ------------------- | -------------------- | ---------------------- |
| `pre-command.sh`    | Before the command   | 1 (allowlist + .env)   |
| `post-command.sh`   | After the command    | 2, 3, 4, 5, 6, 7       |
| `on-exit.sh`        | Final, always         | (summary, no enforcement) |

## Behaviour

All checks are **non-blocking** — they report warnings to stderr but do not abort. Codex doesn't have a tool-layer write gate, so the user reviews the working tree after every run.

## Manual invocation

Useful when wrapping a non-`codex` workflow:

```bash
echo '{"command":"figma-build","args":["https://figma.com/..."]}' | ./.codex/hooks/pre-command.sh
# ... run your workflow ...
echo '{"command":"figma-build","exitCode":0}' | ./.codex/hooks/post-command.sh
./.codex/hooks/on-exit.sh
```

## Extending

When adding a new CLAUDE.md binding rule, also add the parallel check to `post-command.sh` (or `pre-command.sh` if it must gate the run). Use the `[rule N]` prefix in warning messages so the user can trace which rule fired.
