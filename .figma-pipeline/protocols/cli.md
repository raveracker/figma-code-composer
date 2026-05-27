# `figma-code-composer` CLI surface (v1.0)

> Authoritative spec for the `fcc` binary. Stubbed subcommands in this build print "not yet implemented" and exit 0; tracking issues link to where impl will land. Production builds will implement every subcommand here.

The CLI is shipped exclusively via the npm package — consumer projects never import from it. Agents (Claude Code, Cursor, Codex) drive the CLI via `Bash` tool calls. The binary name is `figma-code-composer`; the short alias is `fcc`.

## Global flags

| Flag           | Effect                                            |
| -------------- | ------------------------------------------------- |
| `--help, -h`   | Print help and exit 0                             |
| `--version, -v`| Print version and exit 0                          |
| `--json`       | All output as a single JSON object (no colors, no progress) |
| `--quiet`      | Suppress non-error output                         |
| `--debug`      | Print stack traces on error                       |

Every subcommand also accepts `--help` for subcommand-specific usage.

## Subcommands

> Quick reference of every subcommand:
>
> `init` · `doctor` · `complexity` · `kg:query` · `kg:stage` · `kg:merge` · `kg:rebuild` · `kg:verify` · `kg:repair` · `handover`

### `fcc init [target]`

Scaffold the pipeline into a project. (Default when no subcommand given, for backward compatibility.)

**Flags:**

| Flag                | Effect                                                   |
| ------------------- | -------------------------------------------------------- |
| `--target <dir>`    | Target directory (default: positional arg or cwd)        |
| `--tools <list>`    | Comma-separated: `claude`, `cursor`, `codex` (default: all) |
| `--skip <list>`     | Skip extras: `claude-md`, `agents-md`                    |
| `--force`           | Overwrite existing files                                 |
| `--dry-run`         | Print plan, write nothing                                |
| `--yes, -y`         | Skip prompts; use defaults                               |

**Exit codes:**
- `0` — scaffold installed (or dry run completed)
- `1` — user aborted or conflicts un-resolved
- `2` — invalid flag / unknown tool / target not a directory

---

### `fcc doctor`

Validate the local configuration, MCP reachability, and RTK detection.

**Effect (read-only):**
- Read `.figma-pipeline/config.json`. Validate against `config.schema.json`.
- Print resolved output-structure tree (where each generated artifact will land).
- Check `rtk` binary on PATH. Update `config.rtk.installed` + `config.rtk.version` if changed (writes config.json).
- Check Figma MCP reachability via `mcp__figma__get_metadata` if available; if not, print the manual check.
- Check `.figma-pipeline/kg/` directory health (sqlite-vec readable, ledger.jsonl parseable, no orphan staging dirs).

**Flags:**

| Flag                  | Effect                                                |
| --------------------- | ----------------------------------------------------- |
| `--explain-output`    | Print the resolved output-structure tree only         |
| `--no-write`          | Don't update config.rtk; doctor is fully read-only    |
| `--mcp-skip`          | Skip MCP reachability check                           |

**Exit codes:**
- `0` — all green
- `1` — at least one warning (output, not blocking)
- `2` — config invalid or unreadable
- `3` — MCP unreachable when reachability check enabled

---

### `fcc complexity <manifest>`

Compute and print the complexity score + tier for a manifest JSON file. See [complexity.md](./complexity.md).

**Effect (read-only):**
- Read the manifest at `<manifest>` path.
- If `config.knowledgeGraph.enabled = true`, query the KG for `tokenReuseRatio`.
- Apply the formula; resolve tier against `config.complexity.thresholds`.
- Apply `config.complexity.tierOverrides`.
- Print JSON: `{ score, tier, signals, model, skills }`.

**Flags:**

| Flag                 | Effect                                          |
| -------------------- | ----------------------------------------------- |
| `--no-kg`            | Skip the KG query; assume `tokenReuseRatio = 0` |
| `--print-routing`    | Also print the resolved skill set + model       |

**Exit codes:**
- `0` — score computed
- `2` — manifest unreadable or invalid

---

### `fcc kg:query`

Retrieve top-K most-similar prior ledger entries for a manifest slice. See [knowledge-graph.md](./knowledge-graph.md).

**Effect (read-only):**
- Read the slice at `--slice <path>`.
- Embed `slice.summaryHint` via the configured provider.
- Query `embeddings.sqlite` for top-K by cosine similarity.
- Print JSON array of ledger entries sorted by similarity descending.

**Flags:**

| Flag                 | Effect                                                |
| -------------------- | ----------------------------------------------------- |
| `--slice <path>`     | REQUIRED — path to a slice JSON                       |
| `--top-k <n>`        | Default 5; max 20                                     |
| `--min-similarity <0..1>` | Default 0.3; drop entries below this threshold   |

**Exit codes:**
- `0` — query executed (zero results is success)
- `2` — slice unreadable
- `3` — KG store missing or corrupt

---

### `fcc kg:stage`

Append one ledger entry to a subagent's staging file. Called by each builder after it writes its files.

**Effect (writes, isolated):**
- Validate `--entry` against the ledger entry schema.
- Append a single line to `staging/<runId>/<agent>.jsonl`.
- No cross-agent interaction; no lock needed (each agent owns its own file).

**Flags:**

| Flag                 | Effect                                              |
| -------------------- | --------------------------------------------------- |
| `--run-id <id>`      | REQUIRED                                            |
| `--agent <name>`     | REQUIRED — e.g. `component-builder`                 |
| `--entry <json>`     | REQUIRED — entry as JSON string, OR `--entry-file <path>` |
| `--entry-file <path>`| Alternative to `--entry`                            |

**Exit codes:**
- `0` — staged
- `2` — schema validation failure
- `3` — staging dir unwritable

---

### `fcc kg:merge`

Atomically merge all staged deltas for a run into `ledger.jsonl`. Called by the coordinator after all parallel builders return.

**Effect (writes, locked):**
- Acquire `flock` on `ledger.jsonl`.
- For each `staging/<runId>/*.jsonl`, validate entries, then append.
- Rebuild `graph.json` from the new ledger state.
- Re-embed new `summary` fields into `embeddings.sqlite`.
- Delete `staging/<runId>/`.
- Release lock.

**Flags:**

| Flag                 | Effect                                              |
| -------------------- | --------------------------------------------------- |
| `--run-id <id>`      | REQUIRED                                            |
| `--dry-run`          | Validate + report what would happen; write nothing  |

**Exit codes:**
- `0` — merged (or dry-run validated)
- `2` — at least one staged entry invalid; nothing merged
- `3` — could not acquire lock within 30s
- `4` — embeddings provider failed (ledger merged, embeddings will need `fcc kg:rebuild`)

---

### `fcc kg:rebuild`

Rebuild `graph.json` and `embeddings.sqlite` from the current `ledger.jsonl`. Run manually if the derived files drift.

**Effect:**
- Reads every entry in `ledger.jsonl`.
- Rebuilds `graph.json` from `composes`, `tokensUsed`, `iconsUsed` edges.
- Drops and re-creates `embeddings.sqlite`; re-embeds every entry's `summary`.

**Flags:** none beyond global.

**Exit codes:**
- `0` — rebuilt
- `2` — `ledger.jsonl` unreadable or contains invalid entries

---

### `fcc kg:verify`

Check that ledger entries still match the filesystem. Used by the coordinator before any silent reuse, and at the end of every run; also runs as part of `fcc doctor`.

**Effect (read-only):**
- For each ledger entry (or just `--component-id <id>` when targeted), verify:
  - `filePath` exists.
  - For components/icons: the file contains a named export matching `exportName`.
  - For components: `storyPath` and `testPath` (if set) exist.
  - For tokenSets: each `tokens[].emittedIn` file exists and contains `tokens[].emittedAs`.
- Any failed entry is flagged `orphaned: true` + `orphanedAt: <ISO-8601>` (writes to the ledger; this is the one read-mostly mode where verify mutates).

**Flags:**

| Flag                    | Effect                                                  |
| ----------------------- | ------------------------------------------------------- |
| `--all`                 | Verify every ledger entry                               |
| `--component-id <id>`   | Verify just this entry                                  |
| `--no-write`            | Read-only — don't mutate the ledger even if orphans found |

**Exit codes:**
- `0` — all checked entries verified clean
- `1` — at least one orphan flagged (run continues; report includes the orphan list)
- `2` — `ledger.jsonl` unreadable

---

### `fcc kg:repair`

User-driven cleanup. Never called by agents — only by the user when the run report flags orphans.

**Subcommands:**

| Subcommand                                       | Effect                                                                 |
| ------------------------------------------------ | ---------------------------------------------------------------------- |
| `--prune-orphans`                                | Confirms then removes orphaned entries; writes archive to `.deleted.jsonl` |
| `--prune-orphans --where '<expr>'`               | Same, scoped to entries matching a JSONPath-like expression (e.g. `'framework != "vue"'`) |
| `--rebuild-from-source`                          | Re-runs figma-fetcher + builders for orphaned entries (requires Figma MCP) |
| `--resolve-path <id> <newPath>`                  | Updates `filePath` for a moved file; verifies the new path contains `exportName` |

**Flags:**

| Flag                    | Effect                                                  |
| ----------------------- | ------------------------------------------------------- |
| `--yes, -y`             | Skip confirmation prompts                               |
| `--dry-run`             | Print what would happen                                 |

**Exit codes:**
- `0` — repair applied (or dry-run completed)
- `1` — user declined the action
- `2` — invalid expression or path arguments
- `3` — ledger lock could not be acquired

---

### `fcc handover`

Emit a `handovers/<runId>.md` summarizing a run. Called by the coordinator after `fcc kg:merge` succeeds. See [handover.md](./handover.md).

**Effect:**
- Reads the manifest at `--manifest`.
- Reads merged ledger entries for the run.
- Writes the handover Markdown.

**Flags:**

| Flag                  | Effect                                            |
| --------------------- | ------------------------------------------------- |
| `--run-id <id>`       | REQUIRED                                          |
| `--manifest <path>`   | REQUIRED — path to the run's manifest             |
| `--output <path>`     | Default: `<storeDir>/handovers/<runId>.md`        |
| `--failed`            | Emit a `.failed.md` instead of `.md`              |
| `--verify`            | Re-read disk state and cross-check ledger; flag drift |

**Exit codes:**
- `0` — handover written
- `1` — written with warnings (use `--verify` to surface)
- `2` — manifest or ledger unreadable

## Exit-code conventions (summary)

- `0` — success
- `1` — soft warning, work done
- `2` — bad user input (flags, files)
- `3` — system / external state problem (lock, MCP, sqlite)
- `4` — partial success (intentional fallback path)

Agents that call the CLI MUST treat non-zero as a build failure unless the spec above explicitly allows otherwise.

## What the CLI does NOT do

- **No network**: doctor's MCP check uses the local MCP server. Embedding `provider: local` runs locally. `openai`/`voyage` providers call out — opt-in only.
- **No `git` operations**: never commits, pushes, branches. The CLI writes files; the user controls version control.
- **No `npm publish` or `gh repo create`**: outside scope.
- **No source-file mutations**: only writes to `config.knowledgeGraph.storeDir`, and (for `doctor` only, with consent) `config.json`.

## Versioning

The CLI follows semver. `--version` prints the package version. Subcommand contracts here are versioned with the protocol docs (e.g., this doc is `v1.0`). Breaking changes bump major; additive flags bump minor; bug fixes patch.

Protocol docs and CLI version stay aligned — `fcc --version` printing `1.0.x` means it implements `protocols/cli.md` v1.0.
