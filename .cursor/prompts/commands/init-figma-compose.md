# /init-figma-compose — Cursor command

(Renamed from `/init` so it doesn't collide with Cursor's own init helper / Claude Code's built-in `/init`.)

When the user types `/init-figma-compose` in Cursor agent mode, follow `.cursor/prompts/wizard.md` step-by-step. Do not invoke any other agent or command first.

Trigger phrases: `/init-figma-compose`, "set up figma-pipeline", "configure the pipeline", "run the figma wizard".

Argument: `--re-detect` skips identity and refreshes framework + CSS detection only.
