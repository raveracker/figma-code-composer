# `codex run figma-build <figma-url> [layerHint]`

Mirror of `.claude/commands/figma-build.md`. Dispatches the Codex figma-coordinator with `{ url, intent: "create", scope: "full", layerHint? }`. Same pre-flight: requires `.figma-pipeline/config.json`.

**Two entry points** (see `.codex/README.md` § _Two ways to run_):
- **Plain terminal / CI:** `./codex-run figma-build '<url>'` — wrapper shells out to a nested `codex exec`; hooks fire automatically.
- **Inside an interactive `codex` session:** run this recipe **inline** (follow `.codex/agents/figma-coordinator.md` in the current session — do NOT call `./codex-run` / `codex exec`, which can't nest inside a Codex sandbox). Afterwards run `.codex/hooks/post-command.sh figma-build` for the same manifest/config/token validation.
