#!/usr/bin/env node
// figma-code-composer (fcc) — Figma-to-code multi-agent pipeline scaffold + KG CLI.
//
// Subcommands:
//   init [target]              Scaffold the pipeline into a project (default)
//   doctor                     Validate config, check RTK install, MCP reachability
//   complexity <manifest>      Print complexity score for a manifest JSON
//   kg:query                   Retrieve top-K prior components for a manifest slice
//   kg:stage                   Subagent writes a ledger delta (parallel-safe)
//   kg:merge                   Coordinator merges staged deltas into the ledger
//   kg:rebuild                 Rebuild graph.json + embeddings from ledger.jsonl
//   handover                   Emit handover .md for a run
//
// Legacy: invoking without a subcommand defaults to `init` for backward compat.
//
// Init usage:
//   npx figma-code-composer                            # interactive, current dir
//   npx figma-code-composer init ./my-app              # interactive, target dir
//   npx figma-code-composer init --yes                 # non-interactive, all tools
//   npx figma-code-composer init --tools claude,cursor # specific tools
//   npx figma-code-composer init --force               # overwrite existing files
//   npx figma-code-composer init --dry-run             # print plan, do nothing
//
// Init flags (all optional):
//   --target <dir>     Target directory (default: positional arg or cwd)
//   --tools <list>     Comma-separated: claude,cursor,codex (default: all)
//   --force            Overwrite existing files at target
//   --skip <list>      Comma-separated extras to skip: claude-md,agents-md
//   --dry-run          Show what would happen, write nothing
//   --yes / -y         Skip prompts; use defaults
//   --help / -h        This message
//   --version / -v     Print package version

import { createRequire } from "node:module";
import { readFileSync, existsSync, mkdirSync, cpSync, chmodSync, statSync, readdirSync } from "node:fs";
import { dirname, join, relative, resolve, isAbsolute } from "node:path";
import { fileURLToPath } from "node:url";
import { createInterface } from "node:readline/promises";
import { stdin as input, stdout as output } from "node:process";

const require = createRequire(import.meta.url);
const __dirname = dirname(fileURLToPath(import.meta.url));
const PACKAGE_ROOT = resolve(__dirname, "..");
const PKG = JSON.parse(readFileSync(join(PACKAGE_ROOT, "package.json"), "utf8"));

const TOOL_PATHS = {
  claude: [".claude"],
  cursor: [".cursor"],
  codex: [".codex"],
};
const ALWAYS_PATHS = [".figma-pipeline"];
const EXTRA_PATHS = {
  "claude-md": "CLAUDE.md",
  "agents-md": "AGENTS.md",
};

const COLORS = {
  reset: "\x1b[0m",
  dim: "\x1b[2m",
  bold: "\x1b[1m",
  red: "\x1b[31m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  cyan: "\x1b[36m",
};
const NO_COLOR = !output.isTTY || process.env.NO_COLOR;
const c = (color, str) => (NO_COLOR ? str : `${COLORS[color]}${str}${COLORS.reset}`);

// ─── subcommand dispatcher ──────────────────────────────────────────────────
const KNOWN_SUBCOMMANDS = new Set([
  "init",
  "doctor",
  "complexity",
  "kg:query",
  "kg:stage",
  "kg:merge",
  "kg:rebuild",
  "kg:verify",
  "kg:repair",
  "handover",
]);

const STUB_SUBCOMMANDS = new Set([
  "doctor",
  "complexity",
  "kg:query",
  "kg:stage",
  "kg:merge",
  "kg:rebuild",
  "kg:verify",
  "kg:repair",
  "handover",
]);

async function dispatch(argv) {
  if (argv.includes("--help") || argv.includes("-h")) { printHelp(); process.exit(0); }
  if (argv.includes("--version") || argv.includes("-v")) { printVersion(); process.exit(0); }

  const first = argv[0];
  if (!first || first.startsWith("--") || first.startsWith("-")) {
    return runInit(argv);
  }
  if (KNOWN_SUBCOMMANDS.has(first)) {
    const rest = argv.slice(1);
    if (first === "init") return runInit(rest);
    if (STUB_SUBCOMMANDS.has(first)) return runStub(first, rest);
  }
  // Unknown first arg — treat as legacy positional target for init
  return runInit(argv);
}

function runStub(name, args) {
  console.log(c("yellow", `[fcc ${name}] not yet implemented in this build.`));
  console.log(c("dim", `See .figma-pipeline/protocols/cli.md for the full spec.`));
  console.log(c("dim", `Tracking issue: https://github.com/raveracker/figma-code-composer/issues`));
  process.exit(0);
}

// ─── arg parsing (init) ─────────────────────────────────────────────────────
function parseArgs(argv) {
  const args = {
    target: null,
    tools: null,
    force: false,
    skip: [],
    dryRun: false,
    yes: false,
    help: false,
    version: false,
  };
  const rest = [];
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    switch (arg) {
      case "--target": args.target = argv[++i]; break;
      case "--tools":  args.tools = argv[++i].split(",").map(s => s.trim()).filter(Boolean); break;
      case "--skip":   args.skip = argv[++i].split(",").map(s => s.trim()).filter(Boolean); break;
      case "--force":  args.force = true; break;
      case "--dry-run":args.dryRun = true; break;
      case "--yes": case "-y": args.yes = true; break;
      case "--help": case "-h": args.help = true; break;
      case "--version": case "-v": args.version = true; break;
      default:
        if (arg.startsWith("--")) {
          console.error(c("red", `Unknown flag: ${arg}`));
          process.exit(2);
        }
        rest.push(arg);
    }
  }
  if (!args.target && rest.length > 0) args.target = rest[0];
  return args;
}

// ─── help / version ─────────────────────────────────────────────────────────
function printHelp() {
  console.log(`
${c("bold", "figma-code-composer")} (fcc) — Figma-to-code pipeline scaffold + KG CLI

${c("bold", "Subcommands:")}
  init [target]              Scaffold the pipeline into a project (default)
  doctor                     Validate config, RTK install, MCP reachability
  complexity <manifest>      Print complexity score for a manifest JSON
  kg:query                   Retrieve top-K prior components for a manifest slice
  kg:stage                   Subagent writes a ledger delta (parallel-safe)
  kg:merge                   Coordinator merges staged deltas into the ledger
  kg:rebuild                 Rebuild graph.json + embeddings from ledger.jsonl
  kg:verify                  Check ledger entries still match the filesystem
  kg:repair                  User-driven cleanup: prune orphans, rebuild, resolve paths
  handover                   Emit handover .md for a run

${c("bold", "Init usage:")}
  npx figma-code-composer [target] [options]
  npx figma-code-composer init [target] [options]

${c("bold", "Init options:")}
  --target <dir>     Target directory (default: positional arg or cwd)
  --tools <list>     Comma-separated: claude,cursor,codex (default: all)
  --skip <list>      Comma-separated extras to skip: claude-md,agents-md
  --force            Overwrite existing files at target
  --dry-run          Show what would happen, write nothing
  --yes, -y          Skip prompts; use defaults
  --help, -h         Show this message
  --version, -v      Print package version

${c("bold", "Examples:")}
  ${c("dim", "# Interactive, drops scaffold into cwd")}
  npx figma-code-composer

  ${c("dim", "# Non-interactive, all tools into ./my-app")}
  npx figma-code-composer init ./my-app --yes

  ${c("dim", "# Only Claude Code + Cursor")}
  npx figma-code-composer init --tools claude,cursor --yes

  ${c("dim", "# Skip CLAUDE.md (keep your existing one)")}
  npx figma-code-composer init --skip claude-md --yes

  ${c("dim", "# Short alias")}
  npx fcc init --yes

${c("bold", "After install:")}
  cd <target> && open in your AI tool of choice
  Claude Code: /init
  Cursor:      type /init in agent chat
  Codex CLI:   ./.codex/wrap.sh init
`);
}

function printVersion() {
  console.log(`figma-code-composer ${PKG.version}`);
}

// ─── prompt helpers ─────────────────────────────────────────────────────────
async function askYesNo(rl, question, defaultYes = true) {
  const hint = defaultYes ? "Y/n" : "y/N";
  const answer = (await rl.question(`${question} (${hint}) `)).trim().toLowerCase();
  if (answer === "") return defaultYes;
  return answer === "y" || answer === "yes";
}

async function askChoice(rl, question, defaultValue) {
  const answer = (await rl.question(`${question}${defaultValue ? ` (${defaultValue})` : ""}: `)).trim();
  return answer || defaultValue;
}

// ─── filesystem helpers ─────────────────────────────────────────────────────
function pathExists(p) {
  try { statSync(p); return true; } catch { return false; }
}

function isDir(p) {
  try { return statSync(p).isDirectory(); } catch { return false; }
}

function listConflicts(targetDir, scaffoldEntries) {
  const conflicts = [];
  for (const entry of scaffoldEntries) {
    const target = join(targetDir, entry);
    if (pathExists(target)) conflicts.push(entry);
  }
  return conflicts;
}

function chmodShellScripts(dir) {
  if (!isDir(dir)) return 0;
  let count = 0;
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) {
      count += chmodShellScripts(full);
    } else if (entry.isFile() && entry.name.endsWith(".sh")) {
      try { chmodSync(full, 0o755); count++; } catch { /* noop */ }
    } else if (entry.isFile() && entry.name === "wrap.sh") {
      try { chmodSync(full, 0o755); count++; } catch { /* noop */ }
    }
  }
  return count;
}

function ensureWrapShExecutable(targetDir) {
  const wrap = join(targetDir, ".codex", "wrap.sh");
  if (pathExists(wrap)) {
    try { chmodSync(wrap, 0o755); } catch { /* noop */ }
  }
}

// ─── core: copy ─────────────────────────────────────────────────────────────
function copyEntry(source, target, dryRun) {
  if (dryRun) {
    console.log(`  ${c("dim", "→")} ${relative(process.cwd(), target)}`);
    return;
  }
  const parent = dirname(target);
  if (!pathExists(parent)) mkdirSync(parent, { recursive: true });
  cpSync(source, target, { recursive: true, errorOnExist: false, force: true });
}

function buildPlan(tools, skipExtras) {
  const entries = [...ALWAYS_PATHS];
  for (const tool of tools) {
    if (TOOL_PATHS[tool]) entries.push(...TOOL_PATHS[tool]);
  }
  for (const [key, path] of Object.entries(EXTRA_PATHS)) {
    if (!skipExtras.includes(key)) entries.push(path);
  }
  return entries;
}

// ─── init: scaffolder ───────────────────────────────────────────────────────
async function runInit(argv) {
  const args = parseArgs(argv);

  if (args.help)    { printHelp(); process.exit(0); }
  if (args.version) { printVersion(); process.exit(0); }

  const targetDir = resolve(process.cwd(), args.target || ".");
  console.log(c("bold", "📐 figma-code-composer"));
  console.log(c("dim", `   Target: ${targetDir}`));

  if (!pathExists(targetDir)) {
    if (args.dryRun) {
      console.log(c("yellow", `   (would create) ${targetDir}`));
    } else {
      mkdirSync(targetDir, { recursive: true });
      console.log(c("green", `   Created target dir.`));
    }
  } else if (!isDir(targetDir)) {
    console.error(c("red", `   Target exists but is not a directory: ${targetDir}`));
    process.exit(2);
  }

  let tools = args.tools;
  let skipExtras = args.skip;
  let force = args.force;

  if (!args.yes && !tools && input.isTTY) {
    const rl = createInterface({ input, output });
    try {
      console.log("");
      console.log(c("bold", "Which AI tools should this scaffold wire for?"));
      const wantClaude = await askYesNo(rl, "  Claude Code (.claude/)?", true);
      const wantCursor = await askYesNo(rl, "  Cursor       (.cursor/)?", true);
      const wantCodex  = await askYesNo(rl, "  Codex CLI    (.codex/)?", true);
      tools = [];
      if (wantClaude) tools.push("claude");
      if (wantCursor) tools.push("cursor");
      if (wantCodex)  tools.push("codex");
      if (tools.length === 0) {
        console.error(c("red", "No tools selected — aborting."));
        process.exit(1);
      }
    } finally {
      rl.close();
    }
  } else if (!tools) {
    tools = ["claude", "cursor", "codex"];
  }

  for (const t of tools) {
    if (!TOOL_PATHS[t]) {
      console.error(c("red", `Unknown tool: ${t} (valid: claude, cursor, codex)`));
      process.exit(2);
    }
  }

  const plan = buildPlan(tools, skipExtras);
  console.log("");
  console.log(c("bold", "Scaffold plan:"));
  for (const entry of plan) {
    console.log(`  ${c("cyan", "•")} ${entry}`);
  }
  if (skipExtras.length > 0) {
    console.log(c("dim", `  (skipping: ${skipExtras.join(", ")})`));
  }

  const conflicts = listConflicts(targetDir, plan);
  if (conflicts.length > 0 && !force) {
    console.log("");
    console.log(c("yellow", "⚠ Conflicts (already exist at target):"));
    for (const conflict of conflicts) {
      console.log(`  ${c("yellow", "•")} ${conflict}`);
    }
    if (args.yes) {
      console.error(c("red", "\nRefusing to overwrite. Re-run with --force or remove existing entries."));
      process.exit(1);
    }
    if (input.isTTY) {
      const rl = createInterface({ input, output });
      try {
        const proceed = await askYesNo(rl, "\nOverwrite? Existing files will be replaced.", false);
        if (!proceed) {
          console.log(c("dim", "Aborted by user."));
          process.exit(0);
        }
        force = true;
      } finally {
        rl.close();
      }
    } else {
      console.error(c("red", "\nNo TTY for prompt. Use --force to overwrite or --skip to exclude."));
      process.exit(1);
    }
  }

  console.log("");
  console.log(args.dryRun ? c("yellow", "Dry run — no files written:") : c("bold", "Copying:"));
  for (const entry of plan) {
    const source = join(PACKAGE_ROOT, entry);
    const target = join(targetDir, entry);
    if (!pathExists(source)) {
      console.warn(c("yellow", `  ⚠ Source missing (skipping): ${entry}`));
      continue;
    }
    copyEntry(source, target, args.dryRun);
    if (!args.dryRun) {
      console.log(`  ${c("green", "✓")} ${entry}`);
    }
  }

  if (!args.dryRun) {
    let chmodCount = 0;
    if (tools.includes("claude")) chmodCount += chmodShellScripts(join(targetDir, ".claude", "hooks"));
    if (tools.includes("codex"))  chmodCount += chmodShellScripts(join(targetDir, ".codex", "hooks"));
    if (tools.includes("codex"))  ensureWrapShExecutable(targetDir);
    if (chmodCount > 0) {
      console.log(c("dim", `  (made ${chmodCount} shell script(s) executable)`));
    }
  }

  console.log("");
  console.log(c("bold", args.dryRun ? "Dry run complete." : "✅ Scaffold installed."));
  console.log("");
  console.log(c("bold", "Next steps:"));
  console.log(`  ${c("dim", "1.")} cd ${relative(process.cwd(), targetDir) || "."}`);
  console.log(`  ${c("dim", "2.")} Open the project in your AI tool of choice, then run the wizard:`);
  if (tools.includes("claude")) console.log(`     ${c("cyan", "Claude Code")}  →  /init`);
  if (tools.includes("cursor")) console.log(`     ${c("cyan", "Cursor")}       →  type /init in agent chat`);
  if (tools.includes("codex"))  console.log(`     ${c("cyan", "Codex CLI")}    →  ./.codex/wrap.sh init`);
  console.log(`  ${c("dim", "3.")} Read ${c("cyan", "CLAUDE.md")} for binding rules, ${c("cyan", "AGENTS.md")} for contributor guidelines.`);
  console.log(`  ${c("dim", "4.")} (Optional) install RTK to compress shell-output tokens: ${c("cyan", "brew install rtk && rtk init -g")}`);
  console.log("");
}

// ─── entry ──────────────────────────────────────────────────────────────────
dispatch(process.argv.slice(2)).catch(err => {
  console.error(c("red", `\nError: ${err.message}`));
  if (process.env.DEBUG) console.error(err.stack);
  process.exit(1);
});
