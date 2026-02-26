# agent-setup

Shared tools for AI-assisted development workflows. Currently includes the **Team Knowledge** system — a living knowledge base for multi-contributor projects, optimized for LLM consumption.

Works with multiple AI coding agents: **Claude Code**, **Cursor**, **Codex**, **Gemini CLI**, and **OpenCode**.

## Team Knowledge

Maintains a `TEAM-KNOWLEDGE.md` file that tracks who built what, how domains connect, what changed when, and what conventions the team follows. Any LLM agent can query it naturally ("who owns the sidebar?") or update it explicitly.

### Supported Agents

| Agent | CLI | Headless Command | Status |
|-------|-----|-----------------|--------|
| Claude Code | `claude` | `claude -p --dangerously-skip-permissions` | Stable |
| Codex | `codex` | `codex exec --full-auto` | Stable |
| Gemini CLI | `gemini` | `gemini -p --yolo` | Stable |
| Cursor | `agent` | `agent -p --force` | Stable (20min timeout) |
| OpenCode | `opencode` | TBD | Experimental |

Auto-detection priority: claude > codex > gemini > cursor > opencode

### What's included

```
agent-setup/
├── scripts/
│   ├── detect-agents.sh                   # Detect installed agent CLIs
│   ├── update-team-knowledge.sh           # Multi-agent update script
│   └── install.sh                         # Interactive installer
├── agents/
│   ├── claude/skills/team-knowledge/SKILL.md   # Claude Code skill
│   ├── cursor/commands/team-knowledge.md       # Cursor command
│   ├── codex/instructions-fragment.md          # Codex AGENTS.md fragment
│   ├── gemini/instructions-fragment.md         # Gemini instructions fragment
│   └── opencode/instructions-fragment.md       # OpenCode (experimental)
├── hooks/post-checkout                    # Git hook template
├── templates/
│   ├── TEAM-KNOWLEDGE-TEMPLATE.md         # Starter template
│   └── team-knowledge.conf.example        # Config example
└── skills/team-knowledge/SKILL.md         # Symlink (backward compat)
```

### Quick Install

```bash
# Auto-detect agents and install
bash scripts/install.sh

# Or install globally
bash scripts/install.sh --global

# Or install for a specific agent only
bash scripts/install.sh --agent claude
```

#### Manual install per agent

**Claude Code:**
```bash
mkdir -p ~/.claude/skills/team-knowledge
cp agents/claude/skills/team-knowledge/SKILL.md ~/.claude/skills/team-knowledge/
```

**Cursor:**
```bash
# Project-level (repeat per project)
mkdir -p .cursor/commands
cp agents/cursor/commands/team-knowledge.md .cursor/commands/
```

**Codex:**
```bash
# Append to project's AGENTS.md
cat agents/codex/instructions-fragment.md >> AGENTS.md
```

**Gemini CLI:**
```bash
# Append to project's GEMINI.md
cat agents/gemini/instructions-fragment.md >> GEMINI.md
```

### Configuration

The script auto-detects everything from the current working directory:
- **Repo** — from `git rev-parse --show-toplevel`
- **Branch** — first of `dev`, `main`, `master` found in remote refs
- **Knowledge file** — `../TEAM-KNOWLEDGE.md` or `./TEAM-KNOWLEDGE.md`
- **Agent CLI** — first available in priority order

For custom setups, create `.team-knowledge.conf` in the repo root:

```bash
# .team-knowledge.conf
KNOWLEDGE_FILE="../TEAM-KNOWLEDGE.md"
BASE_BRANCH="dev"
PROJECT_NAME="my-project"
AGENT_CLI="auto"    # auto | claude | cursor | codex | gemini | opencode
```

See `templates/team-knowledge.conf.example` for all options.

Or use environment variables:

```bash
AGENT_CLI=codex REPO_DIR=/path/to/repo bash update-team-knowledge.sh
```

### Agent Detection

Check what's available on your system:

```bash
# Bash-sourceable output
bash scripts/detect-agents.sh

# JSON output
bash scripts/detect-agents.sh --json
```

### Usage

#### Natural queries (implicit)

Just ask your AI assistant questions — the skill triggers automatically:

- "Who built the sidebar?"
- "What PRs touched the auth module?"
- "If I change the Task model, what breaks?"
- "What conventions does the team follow for API routes?"

#### Explicit commands

```
/team-knowledge update              # Incremental update from git history
/team-knowledge update --force      # Force full update
/team-knowledge update --dry-run    # Preview changes without updating
/team-knowledge init                # Bootstrap for a new project
/team-knowledge status              # Show last processed state
```

### How it works

1. **Agent detection** — Finds which agent CLIs are installed (or uses configured `AGENT_CLI`)
2. **State tracking** — `.team-knowledge-state` records the last processed commit and PR number
3. **Change detection** — Compares current `origin/<base-branch>` HEAD against stored state
4. **Summary generation** — Builds a compact diff summary (commits, PRs, files, contributors)
5. **Agent dispatch** — Calls the resolved agent's headless mode to surgically edit TEAM-KNOWLEDGE.md
6. **State update** — On success, records the new state to skip next time

### Requirements

- At least one supported AI coding agent CLI in PATH
- Git
- Bash 4+

### Troubleshooting

| File | Purpose |
|------|---------|
| `/tmp/team-knowledge-update.log` | Full execution log |
| `/tmp/team-knowledge-summary.txt` | Last generated change summary |
| `.team-knowledge-state` | State file (delete to force full scan) |

**Agent-specific notes:**
- **Cursor:** The `agent -p` headless mode may hang in some environments. A 20-minute timeout is applied automatically.
- **OpenCode:** Headless mode syntax is not yet documented. Marked as experimental.
- **Codex:** Requires the working directory to be a git repository.

## License

MIT
